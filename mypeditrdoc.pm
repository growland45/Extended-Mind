package mypeditrdoc;
use Tk;
use myf::frdoc; use mypitem;
use mylib::db;  use mytk::g;  use mytk::tabpane;  use mytk::srecedit;
@ISA = ('tabpane');

#-----------------------------------------------------------------

sub btext { my ($self)=@_;
  return "Edit Linked Doc";
}

sub launch  {  my ($self, $spec)= @_;
  #print "pinewrdoc::launch key='$key'\n";
  my $args= {spec=>$spec};
  $self->destroy(); # in case re-use.
  my $frdoc= $self->{frdoc}= frdoc->new($args);
  $self->{spec}= $spec;
  return $frdoc;
}

 
sub populate {  my ($self)= @_;
  my $w= $self->{window};
  my $frdoc= $self->{frdoc};
  $frdoc->{importance}= 1;  $frdoc->{title}= '';  #defaults
  $frdoc->readfields();

  my $cr= $w->{cr}= g::ctlrow($w);
  g::menu_button($cr, 'Save', [\&_save, $self]);
  g::menu_button($cr, 'Fetch title', [\&g_fetchtitle, $self, 0]);
  g::menu_button($cr, '(no proxy)', [\&g_fetchtitle, $self, 1]);
  g::label($cr, substr($self->{spec},0, 50));

  my $cr2= g::ctlrow($w);
  g::label($cr2, "Importance:", 0);
  my @impls= ('0', '1', '2', '3');
  g::optmenu($cr2, \$frdoc->{importance}, \@impls);
  g::checkbox($cr2, 'Dynamic', \$frdoc->{dynamic});
  g::checkbox($cr2, 'Peruse', \$frdoc->{peruse});
  g::checkbox($cr2, 'Alt. browser', \$frdoc->{altbrowse});
  $w->{title}= g::entry($cr2, 60, $frdoc->{title}, 1, 1, 1);

  my $gritems= g::grid($w, 2);  $gritems->{maxfont}= 1;
  g::label($gritems, "Associated with:");
  g_ritems($frdoc->{spec}, $gritems);

  $w->{sspane}= g::colframe($w);
  if ($frdoc->{isscansite})  { $self->pop_scansite(); }
  else { $self->pop_nonscansite(); }
}


sub g_ritems { my ($spec, $g)=@_;
  my %ritems;
  frdoc::get_byspec($spec, \%ritems);
  my $cr1;  $cr1= g::ctlrow($g, 0) unless g::grid_nomore($g);

  my $orphaned= 1;
  foreach my $key (sort keys %ritems) {
    $orphaned= 0;
    my $frdoc= $ritems{$key};
    my $kitem= $frdoc->{key};
    my $fitem= fitem::fitem_from_key($kitem);
    my @aitem= ($fitem->{name}, $fitem->{key}, $fitem->{importance});
    main::g_itembutton($cr1, \@aitem, $bwid)  if defined($cr1);
  }
  if ($orphaned)  {
    g::menu_button($g, substr($title, 0, 40), [\&g_launchspec, $spec], $fsz);
    g::label($g, "ORPHAN: $spec");
  };
}


sub _gmakescansite {  my ($self)= @_;
  my $w= $self->{window};
  my $frdoc= $self->{frdoc};
  $w->{sspane}->destroy();
  my $sspane= $w->{sspane}= g::colframe($w);
  $frdoc->makescansite();
  $self->pop_scansite();
}

sub pop_nonscansite {  my ($self)= @_;
  my $w= $self->{window};
  my $sspane= $w->{sspane};
  g::menu_button($sspane, "Make scanned site", [\&_gmakescansite, $self]);
}

sub pop_scansite {  my ($self)= @_;
  my $w= $self->{window};
  my $frdoc= $self->{frdoc};
  my $sspane= $w->{sspane};
  $gre= $w->{gre}= srecedit->new($w,
                                   {listener=>$self, rec=>$frdoc,
                                    fields=>\@frdoc::tscansite_fields, nkey1=>'spec'});
  g::menu_button($w, "Scan", [\&main::gdoswcmd, 'mypscansite', $frdoc->{spec}]);
}

sub cb_onsave {  my ($self, $rec, $isnew)= @_;
  my $dbrec= dbrec->new($rec, $frdoc::tscansite);
  $dbrec->save($isnew);
}

sub cb_ondelete {  my ($self, $rec)= @_;
  my $dbrec= dbrec->new($rec, $frdoc::tscansite);
  $dbrec->delete();
  $frdoc->{isscansite}= 0;
  my $sspane= $w->{sspane};
  $sspane->destroy()  if defined($sspane);
  $self->pop_nonscansite();
}


sub _save  { my ($self)= @_;  $self->g_save(); } # may override in derived class

sub g_save  { my ($self)= @_;
  g::timer_reset();
  my $w= $self->{window};
  my $frdoc= $self->{frdoc};
  $frdoc->{title}= g::entry_get($w->{title});
  $frdoc->save();
  #print "g_save title '$frdoc->{title}'\n";
}

sub g_fetchtitle  { my ($self, $noproxy)= @_;
  g::timer_reset();
  my $w= $self->{window};
  my $frdoc= $self->{frdoc};
  #print "g_fetchtitle for '$frdoc->{spec}' tries=$frdoc->{titletries} noproxy=$noproxy\n";
  my $title=  $frdoc->title($noproxy, 1);
  return  unless defined($title)  and $title ne '';
  g::entry_set($w->{title}, $title)  if defined($title);
}

1;

