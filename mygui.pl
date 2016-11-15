#!/usr/bin/perl
# usage:  host/path/filename user password

# Requirements:
# cpan install String::Util
# cpan install Text::Metaphone
# cpan install Filesys::Df

use Tk;  use English;
use myf::f;  use myf::fitem;  use myf::frdoc;
use mytk::g;  use mytk::gcore;  use mytk::tabrow;

our $onwindows= $^O eq 'MSWin32';

@raisables= ('mypactions', 'mypnonactions', 'mypdynamics', 'mypperuses');

sub main  {
  my $argv0= $ARGV[0];  $argv0= undef  if $argv0 eq '';  
  g::justone('mygui')  unless defined($argv0);
  f::init($argv0);
  system("ulimit -v 9123456")  unless $onwindows;

  our $mw= g::tabbedmainwindow('Extended Mind '. f::title());

  #  icon...
  my $newlogo = $mw->Photo(-file => "mygui.gif", -format => 'gif');
  $mw->Icon(-image =>$newlogo);

  $tabrow= $mw->{tabrow};

  $tabrow->classtab('mypactions', undef, 1);
  $tabrow->classtab('mypsearch');
  $tabrow->classtab('mypdynamics');
  $tabrow->classtab('mypnonactions');
  $tabrow->classtab('mypperuses');
  $tabrow->classtab('mypedittables');
  g::mwmaximize();
  gui_autoraise();

  print "Entering main loop...\n";
  MainLoop;
  f::deinit();
  g::endone();
}


#=====================================================================

sub g_itembutton { my ($parent, $qitem, $wid)= @_;
  $wid= 40  unless defined($wid);
  my ($name, $key, $importance)= @$qitem;    #print "gui_fillsnonaction: $name\n";
  $importance= $gcore::maxfont  if $importance> $gcore::maxfont;
  my $fsz= $importance;  $wid-= 3*$importance;
  my $btext= substr($name, 0, $wid);
  g::menu_button($parent, $btext, main::glaunchswcmd('mypitem', $key), $fsz);
}

sub glaunchswcmd { my ($class, $key1, $key2, $key3)= @_;
  return [\&tabrow::launchsw, $tabrow, $class, $key1, $key2, $key3];
}

sub gdoswcmd  { my ($class, $key1, $key2, $key3)= @_;
  return tabrow::launchsw($tabrow, $class, $key1, $key2, $key3);
}

sub glaunchbutton { my ($parent, $btext, $key, $fsz)= @_;
  $fsz= 0 unless defined($fsz);  $fsz= 0  if $fsz< 0;
  return g::menu_button($parent, $btext, glaunchswcmd('mypitem', $key), $fsz);
}

sub glaunchsecbtn  {  my ($parent, $btext, $secid, $fsz)= @_;
  $fsz= 0 unless defined($fsz);  $fsz= 0  if $fsz< 0;
  g::menu_button($parent, $btext, glaunchswcmd('mypitem', undef, $secid), $fsz);
}

sub glaunchrandom  {
  my $ikey= mypitem::chooserandom();
  #print "glaunchrandom ikey='$ikey'\n";
  $tabrow->launchsw('mypitem', $ikey);
}

#-------------------------------------------------------------------------------------
# a list of butons for items which satisfy certain conditions

sub g_popflag { my ($prow, $flag, $title, $maxw)= @_; # mypactions, mypnonactions
  my $pn= 'p'. $flag;
  my $p= $prow->{$pn}= g::colframe($prow);
  g::label($p, $title);
  my $bg= g::grid($p, 1, 40);
  my %bundle;  $bundle{bg}= $bg;  $bundle{maxw}= $maxw;
  fitem::f_enumerate_itemkeys_flag(\&g_popflag_callback, $flag, \%bundle);
}

sub g_popflag_callback  { my ($rec, $rbundle)= @_;
  my $bg= $rbundle->{bg};
  return 0  if g::grid_nomore($bg);
  my @aitem= ($rec->{name}, $rec->{key}, $rec->{importance});
  main::g_itembutton($bg, \@aitem, $rbundle->{maxw});
  return 1; 
}


sub g_popgrid  { my ($p, $l, $showtype, $cols, $maxrows)= @_; # mypactions, mypempties
  $showtype= 1  unless defined($showtype);
  $cols= 1  unless defined($cols);
  my $gt= g::grid($p, (2+ $showtype)* $cols, $maxrows);
  foreach $key (sort keys %$l)  {
    g_pop_section($l->{$key}, $gt, $showtype);
    last  if g::grid_nomore($gt);
  }
}

sub g_pop_section  { my ($fse, $g, $showtype, $fsz)=@_;
  my $iname= fitem::f_textfromkey($fse->{ikey}, 20);
  g::label($g, $iname, 0);
  my $twid= 30;
  if ($showtype)  {
    g::label($g, substr($fse->{type}, 0, 6), 0);
    $twid-= 6;
  }
  $fsz= $fse->{importance}  unless defined($fsz);
  $twid-= $fsz*2;
  my $btext= substr($fse->{title}, 0, $twid);
  my $secid= $fse->{id};  #print "gui_isearch: '$secid'\n";
  main::glaunchsecbtn($g, $btext, $secid, $fsz);
}

sub g_popsearchdocresults { my ($itemframe, $listbyspec)= @_; # mypersuses, mypsearch
  my $bwid=27;
  my $g= g::grid($itemframe, 2, 30);
  foreach my $skey (sort keys %$listbyspec)  {
    last  if g::grid_nomore($g);

    my $frdoc= $listbyspec->{$skey};
    #my $ref= ref $frdoc; if ($ref ne 'frdoc')  { print "skey=$skey, ref frdoc=$ref\n"; last; }
    my $spec= $frdoc->{spec};  my $title= $frdoc->btntitle();
    next  unless defined($spec)  and $spec ne '';
    #print "gui_isearchdocs: $spec - > $title\n";
    my $fsz= $frdoc->{importance};  $fsz= 0  if $fsz< 0;
    my $cr= g::ctlrow($g, 0);
    g::control_button($cr, 'E', [\&main::gdoswcmd, 'mypeditrdoc', $spec], 0);
    g::menu_button($cr, substr($title, 0, 50-$fsz*2), [\&g_launchspec, $spec], $fsz);
  }
}

sub g_launchspec { my ($spec, $noproxy)= @_;
  g::timer_reset();
  frdoc::launchspec($spec, $noproxy);
}



#=====================================================================

sub gui_autoraise  {
  g::mwraise();
  g::timer(30, \&g_raise);
}

sub g_raise  {
  my $i= int(rand(scalar(@raisables)));
  gdoswcmd($raisables[$i]);
  g::mwraise();
}


sub gui_mwgone { $mw->withdraw; }
sub gui_mwback {
  gui_mwrefresh();
  $mw->deiconify;  $mw->raise;
  g::mwmaximize();
}

sub gui_mwrefresh  {
  f::refresh(); # cached data
  $tabrow->refresh();
}

main();

