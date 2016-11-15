package pimain;
use Tk;
use myf::fitem;  use myf::f;  use myf::frelate;
use mytk::g;  use mytk::tp;  use mytk::tabpane;
use mypi::mrelates;  use mypi::mrdocs;  use mypi::msecsum;
@ISA = ('tabpane');

$dwid= 55;  $drows= 4;

sub btext { my ($self)=@_;
  return 'Main';
}

sub set { my ($self, $fitem)= @_;
  $self->destroy(); # in case re-use.
  $self->{fitem}= $fitem;
}


sub populate {  my ($self)= @_;
  my $w= $self->{window};
  #print "pimain::populate self=$self w=$w...\n";
  my $fitem= $self->{fitem};
  $fitem->choose_maindoc();

  my $scroller= g::frame_scrolled($w);
  my $twopanes= $w->{twopanes}= g::rowframe($scroller);
  my $lpane= g::colframe($twopanes);
  my $ocr= g::ctlrow($lpane, 1);

  my $lcr= g::ctlrow($ocr, 0);
  g::label($lcr, "Importance ", 0);
  my @impls= ('0', '1', '2', '3');
  $w->{implmenu}= g::optmenu($lcr, \$fitem->{importance}, \@impls);
  #g::checkbox($lcr, 'Action focus', \$fitem->{actfocus});
  g::checkbox($lcr, 'Ponder Focus', \$fitem->{ponderfocus});

  my $crcmd= $w->{crcmd}= g::ctlrow($ocr, 0);
  g::menu_button($crcmd, 'Revert', [\&revert, $self]);
  g::menu_button($crcmd, 'Save', [\&save, $self]);

  $w->{desc}= tp::tpmake($lpane, \$fitem->{desc}, $drows, $dwid);
  
  my $rpane= $w->{rpane}= g::colframe($twopanes);
  $self->pop_urpane($rpane);

  my $twopanes2= g::rowframe($scroller);

  my %krfrom;
  frelate::get_fromrelates($fitem->{key}, \%krfrom);
  my $rcnt= $self->{rcnt}= scalar (keys %krfrom);

  my $dangles= mrdocs::f_fetchdangles($fitem);
  my $dcnt= scalar(keys %$dangles);

  if ($rcnt<=5 or $dcnt<=5) {  #...  'News Sites' all one vertical column
    my $mrdocs= $w->{mrdocs}= mrdocs->new($scroller, {pimain=>$self, dangles=>$dangles, wide=>1});
    mrelates->new($scroller, {pimain=>$self, krfrom=>\%krfrom, wide=>1});
    $w->{msecsum}= msecsum->new($scroller, {pimain=>$self, wide=>1});
    #g::label($scroller, f::get_thoughtprompt(), 1);
    $self->maybe_pop_delbtn();
    return;
  }

  # from relates in left column
  my $rin= g::colframe($twopanes2);
  mrelates->new($rin, {pimain=>$self, krfrom=>\%krfrom});
  my $rdin= g::colframe($twopanes2);
  my $mrdocs= $w->{mrdocs}= mrdocs->new($rdin, {pimain=>$self, dangles=>$dangles});

  my $dexcesscnt= $rcnt- $dcnt;
  #print "pimain dexcesscnt= $rcnt-$dcnt= $dexcesscnt\n";
  if ($dexcesscnt> 2)  {
    $w->{msecsum}= msecsum->new($rdin, {pimain=>$self});
  } else  {
    $w->{msecsum}= msecsum->new($scroller, {pimain=>$self, wide=>1});
  }
    
  #g::label($scroller, f::get_thoughtprompt(), 1);

  $self->fillfields();
  #print "...pimain::populate\n";

}

sub pop_urpane {  my ($self, $rpane)= @_;
  my $fitem= $self->{fitem};
  $self->{urpanecnt}= 0;
  #print "pop_urpane $rpane\n";

  my $cr= g::ctlrow($rpane, 1);
  g::label($cr, 'Need attention:');

  $grid= g::grid($rpane, 1, 3);
  $grid->{mfsz}= 0;  $grid->{maxfsz}= 1;  $grid->{bwid}= $dwid + $dwid/3;
  $self->pop_urpane_items($grid, 'date', 1);
  $self->pop_urpane_items($grid, 'todo', 1);
  $self->pop_urpane_items($grid, 'wait', 1);
  $self->pop_urpane_items($grid, 'questions', 0);
}

sub pop_urpane_items { my ($self, $grid, $type, $isaction)= @_;
  my %s;  $self->{fitem}->get_sectionlist($type, \%s);
  foreach my $key (sort keys %s)  {
    my $not= $s{$key};
    $self->{pitem}->pop_not($not, $grid, $isaction);
    $self->{urpanecnt}++;
  }
}


sub maybe_pop_delbtn  { my ($self)= @_;
  return if $self->{rcnt}> 0;

  my $fitem= $self->{fitem};
  return if $fitem->{desc} ne '';
  return if $self->{urpanecnt}> 0;

  my $w= $self->{window};
  return if defined($w->{mrdocs}) and $w->{mrdocs}->{cnt}> 0;
  return if defined($w->{msecsum}) and $w->{msecsum}->{cnt}> 0;

  return  if defined($w->{delbtn});
  my $crcmd= $w->{crcmd};
  $w->{delbtn}= g::menu_button($crcmd, 'DELETE', [\&delentry, $self]);
}

#----------------------------------------------------------------------------------


sub load  { my ($self, $newname)= @_;
  #print "myitempane::load(self=$self newname=$newname)\n";
  my $fitem= $self->{fitem};
  return  if $newname eq $fitem->{name}; # nothing to do
  $self->save();
  $fitem->{name}= $newname;
  $self->revert();
}

sub revert {  my ($self)= @_;
  $self->readfields();
  $self->fillfields();
}

sub readfields { my ($self)= @_;
  $self->{fitem}->readfields();
  $self->fillfields();
}

sub fillfields { my ($self)= @_;
  my $fitem= $self->{fitem};
  my $w= $self->{window};
  my $desc= $w->{desc};  tp::tpload($desc)  if defined($desc);
}

sub save  {  my ($self)= @_;
  g::timer_reset();
  $self->unload();
  $self->{fitem}->save();
  $self->maybe_pop_delbtn();
}

sub unload  {  my ($self)= @_;
  my $fitem= $self->{fitem};
  my $w= $self->{window};  my $desc= $w->{desc};
  tp::tpunload($desc, $fitem->{desc})  if defined($desc);
}

sub delentry  { my ($self)=@_;
  g::timer_reset();
  $self->{fitem}->delentry();
  main::gdoswcmd('mypactions');
}

1;


