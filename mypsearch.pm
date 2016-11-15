package mypsearch;
use Tk;
use myf::fitem;  use myf::frdoc;  use myf::fsecentry;
use mypitem;  # recents
use mytk::g;  use mytk::tabpane;
@ISA = ('tabpane');

sub btext { my ($self)=@_;
  return 'Search/New';
}

sub populate  { my ($self)= @_;
  my $w= $self->{window};
  my $prow= g::rowframe($w);
  my $sp= $w->{sp}= g::halfscroller($prow, 1);
  my $ctlrow= $sp->{ctlrow};
  my $cr1= g::ctlrow($ctlrow, 0);
  $w->{wscratch}= g::entry($cr1, 25, $self->{srchptn}, undef, 1);
  g::menu_button($cr1, 'Search', [\&gui_isearch, $self]);
  g::label($ctlrow, f::get_thoughtprompt(), 5);
  g::menu_button($ctlrow, 'Random', \&main::glaunchrandom);

  g::halfscroller_clear($sp);
  $w->{src}= g::colframe($sp->{itemframe}); # keep search results in position above recents
  $self->gui_isearch();
  $self->pop_recents();
}


sub pop_recents { my ($self)= @_;
  my $w= $self->{window};  my $sp= $w->{sp};
  my $if= $sp->{itemframe};
  my $key= $mypitem::latestitem;
  return  unless defined($key);

  my $cr1= g::ctlrow($if, 0);
  g::label($cr1, "Most recent:");
  my $btext= _btextfromkey($key);
  main::glaunchbutton($cr1, $btext, $key, 2);

  my $recentitems= mypitem::recentitems();
  my @skitems= sort keys %$recentitems;
  my $rcols= 4;  my $fsz= 2;  my $tsz=30;
  my %ritems= ();
  my $rg= g::grid($if, $rcols);
  g::label($rg, 'More recents:');
  foreach $key (@skitems)  { 
    $btext= _btextfromkey($key);
    next unless defined($btext);
    $ritems{$btext}= $key;
  }
  foreach my $btext (sort { "\L$a" cmp "\L$b" } keys %ritems)  {
    my $key= $ritems{$btext};
    main::glaunchbutton($rg, substr($btext, 0, $tsz), $key, $fsz);
  }

  #my $rctdocpane= g::colframe($prow);
  #g::label($rctdocpane, "Recent documents:");
  #my $rdscroller= g::frame_scrolled($rctdocpane);
  #$g= g::grid($rdscroller, 1);
  #foreach my $spec (sort keys %frdoc::recentdocs)  {
  #  my $title= frdoc::fetchdoctitle($spec);
  #  my $btext= $title; $btext= substr($btext, 0, 60);
  #  glaunchdocbutton($g, $btext, $spec);
  #}

}

#sub glaunchdocbutton { my ($parent, $btext, $key, $fsz)= @_;
#  return g::menu_button($parent, $btext, [\&frdoc::launchspec, $key], $fsz);
#}

sub _btextfromkey { my ($key, $l)= @_;
  $l= 50 unless defined($l);
  my $fitem= fitem->new({key=>$key});  return undef  unless defined($fitem);
  $fitem->readfields();
  my $name= $fitem->{name};
  return undef  unless defined($name);  return undef if $name eq '';
  my $btext= $name; $btext= substr($btext, 0, $l);
  return $btext;
}

#==========================================================================================

sub glaunchdocbutton { my ($parent, $btext, $key, $fsz)= @_;
  return g::menu_button($parent, $btext, [\&frdoc::launchspec, $key], $fsz);
}

sub gui_isearch { my ($self)= @_;
  g::timer_reset();
  my $cols= 4;
  my $w= $self->{window};  my $src= $w->{src};
  my $srf= $w->{srf};  $srf->destroy()  if defined($srf);
  $srf= $w->{srf}= g::colframe($src, 1,0,1);

  my $pattern= $self->{srchptn}= $w->{wscratch}->get();
  return  if $pattern eq '';

  my $listbyname= {};
  f::search($listbyname, $pattern, 10, 30);
  $have= 0;
  my $g= g::grid($srf, $cols);
  foreach my $skey (sort keys %$listbyname)  {
    my $ritem= $listbyname->{$skey};  my @aitem= @$ritem;
    $have= 1  if lc($aitem[0])  eq lc($pattern);
    main::g_itembutton($g, \@aitem, 50);
  }
  unless ($have)  {
    my $cr1= g::ctlrow($srf, 0);
    my $wouldbekey= db::abbrev($pattern);
    my $fitem= fitem::fitem_from_key($wouldbekey);
    if (defined($fitem))  { # key collision
      g::label($cr1, "Collides with:");
      g::menu_button($cr1, $fitem->{name}, main::glaunchswcmd('mypitem', $wouldbekey), 2);
    }  else  {
      my $nscratch= $self->{nscratch}= g::entry($cr1, 30);
      g::entry_set($nscratch, $pattern);
      g::menu_button($cr1, 'New', [\&gui_inew, $self]);
    }
  }
  $srf->{nbtn}= g::menu_button($srf, 'SEARCH SECTIONS NEXT', [\&gui_isearchsections, $self, $pattern]);
}

sub gui_inew {  my ($self)= @_;
  my $fitem= fitem->new();
  my $name= $self->{nscratch}->get();
  my $key= $fitem->newentry($name);
  return 0  unless defined($key) and $key ne '';
  main::gdoswcmd('mypitem', $key);
  return 1;
}


sub gui_isearchsections { my ($self, $pattern)= @_;
  my $w= $self->{window};  my $srf= $w->{srf};
  g::timer_reset();
  $srf->{nbtn}->destroy()  if defined($srf->{nbtn});
  my $cols= 2;
  #print "gui_isearchsections...\n";
  my %listbyspec;
  fsecentry::f_search(\%listbyspec, $pattern, 30);
  g::label($srf, "Sections...");
  my $g= g::grid($srf, 3* $cols);
  foreach my $key (sort keys %listbyspec)  {
    _pop_section($listbyspec{$key}, $g);
  }
  $srf->{nbtn}= g::menu_button($srf, 'SEARCH DOCS NEXT', [\&gui_isearchdocs, $self, $pattern]);
}

sub _pop_section  { my ($fse, $g)=@_;
  my $iname= fitem::f_textfromkey($fse->{ikey}, 20);
  g::label($g, $iname, 0); 
  g::label($g, substr($fse->{type}, 0, 4), 0); 
  my $btext= substr($fse->{title}, 0, 35);
  my $id= $fse->{id};  #print "gui_isearch: '$id'\n";
  main::glaunchsecbtn($g, $btext, $id);
}


sub gui_isearchdocs { my ($self, $pattern)= @_;
  #$DB::single = 1;
  #print "gui_isearchdcs...\n";
  g::timer_reset();
  my $w= $self->{window};  my $srf= $w->{srf};
  $srf->{nbtn}->destroy();
  my %listbyspec;
  frdoc::search_doctitle(\%listbyspec, $pattern, 1, 30);
  g::label($srf, "Documents...");
  main::g_popsearchdocresults($srf, \%listbyspec);
}

1;

