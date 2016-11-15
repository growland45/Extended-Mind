package g;
use mytk::gcore;  use mytk::gpalette;  use mytk::tabrow;
use Tk;  use Tk::Font;  use Tk::Pane;
use utf8;  use English;

our $onwindows= int($^O eq 'MSWin32');
print "g running on $^O\n";
if ($onwindows)  {
  require Win32::Clipboard;
}

our $mw, $mwtimer, $timerminutes, $timercmd;  # to create fonts, timer

# ------------------------------------------------------------------------

sub tabbedmainwindow { my ($title, $newclr)= @_;
  mainwindow($title, $newclr);
  my $cr= g::ctlrow($mw); # nesting them gives nicer alignment
  $mw->{scratch}='';
  my $tabrow= tabrow->new({parent=>$cr, labelvar=>\$mw->{scratch}, mainpanel=>$mw},
                           undef, 1);
  $mw->{tabrow}= $tabrow;
  $mw->state('normal');
  return $mw;
}

sub mainwindow { my ($title, $newclr)= @_;
  gcore::init_palette($newclr);
  $mwtitle= $title;
  $mw= MainWindow-> new(-bg=> $gcore::clr{bg}, -title=> $title);
  gcore::init_fonts($mw);
  if (!defined($mw))  { print "Could not create window!\n";  exit(1); }
  $mw->{pos}= 't';  $mw->{wide}= 1;
  return $mw;
}

sub mwtitlesuffix { my ($title)=@_;  $mw->title($mwtitle. ' '. $title);  }

sub mwmaximize  {
  #[not accepted]$mw->state('zoomed');
  $mw->state('normal');
  my $w= $mw->screenwidth;
  my $h= $mw->screenheight-50;  $h-= 50  if $onwindows;
  #print "w: $w\n";  print "h: $h\n";
  $mw->geometry("${w}x$h+0+0");
  mwraise();
}

sub mwmaxhgt  {
  #[not accepted]$mw->state('zoomed');
  $mw->state('normal');
  my $w= $mw->screenwidth*3/4;
  my $h= $mw->screenheight-50;  $h-= 50  if $onwindows;
  #print "w: $w\n";  print "h: $h\n";
  $mw->geometry("${w}x$h+0+0");
  mwraise();
}

sub mwraise  {
  return unless defined($mw);
  #print "Raising mw\n";
  $mw->raise();
  $mw->focus();
}

#=====================================================================

sub justone { my ($appname)= @_;
  return  if $onwindows;
  $home= $ENV{'HOME'};
  $pidfile= "$home/.$appname.pid";
  print "justone '$pidfile' pid='$PID'\n";

  if (-e $pidfile)  {
    open I, "<$pidfile";
    my $opid= 0+ <I>;
    close I;
    print "Was running as '$opid'\n";
    # http://stackoverflow.com/questions/3844168/how-can-i-check-if-a-unix-process-is-running-in-perl
    my $exists = kill 0, $opid;
    if ($exists) {
      print "  ...still running\n";
      system("ps | grep $pid");
      exit(-1);
    }
  }

  open O, ">$pidfile";
  print O "$PID\n";
  close O;
}

sub endone  {
 unlink($pidfile);
}

#=====================================================================

sub timer { my ($minutes, $cmd)=@_;
  $minutes= $timerminutes  unless defined($minutes);
  $cmd= $timercmd  unless defined($cmd);
  $timerminutes= $minutes;  $timercmd= $cmd;
  return unless defined($mw) and defined($minutes) and defined($cmd);
  #my $t= int(time()/60)%60;  print "Setting timer for $minutes minutes at $t\n";
  $mwtimer= $mw->repeat($minutes * 60000, $cmd);
}

sub timer_reset  {
  timercancel();
  #$DB::single = 1;
  timer();
}

sub timercancel  {
  return unless defined($mwtimer);
  #print "timercancel $mwtimer\n";
  $mwtimer->cancel();
  $mwtimer= undef;
}

# ------------------------------------------------------------------------

sub colframe { my ($parent, $litecolor, $scrolled, $border)= @_;
  #return  grid($parent, 1, undef, $litecolor, $border, 1);
  $border= 0  unless defined($border);
  my $f= gcore::frame($parent, $litecolor, $scrolled, $border);
  #my $r= ref $f;  print "colframe returns $f type ref='$r'\n";
  $f->{pos}= 't';  return $f;
}

sub rowframe { my ($parent, $litecolor, $scrolled, $border)= @_;
  #return  grid($parent, 99, 1, $litecolor, $border, 1);
  my $f= gcore::frame($parent, $litecolor, $scrolled, $border);
  $f->{pos}= 'l2r';
  return $f;
}

sub frame_scrolled  { my ($parent, $scrolls, $litecolor, $border)= @_;
  $scrolls= 1  unless defined($scrolls);
  $litecolor= 1  unless defined($litecolor);
  $border= 1  unless defined($border);
  return gcore::frame($parent, $litecolor, $scrolls, $border);
}


#--------------------------------------------------------------------

sub grid  {  my ($parent, $cols, $maxrows, $litecolor, $border, $wide)= @_;
  $DB::single= 1  unless defined($parent);
  $fsz= 1  unless defined($fsz);
  $litecolor= 1  unless defined($litecolor);
  $border= 1  unless defined($border);
  $cols= 1  unless defined($cols);
  $wide= 0 unless defined($wide);
  my $bgcolor= gcore::choosebgcolor($litecolor);
  my $bg= undef;
  if ($border)  {  $bg= $parent->Frame(-bg=>$bgcolor, -borderwidth=>2, -relief=>raised);  }
  else  {  $bg= $parent->Frame(-bg=> $bgcolor);  }
  $bg->{wide}= $wide;
  $bg->{cols}= $cols;  $bg->{maxrows}= $maxrows;
  $bg->{col}= 0;  $bg->{row}= 0;
  $bg->{pos}= 'grid';
  #print "Grid $bg, parent is $parent\n";
  gcore::mypack($bg, $parent, 0);
  return $bg;
}

sub grid_nomore { my ($grid)= @_;
  my $maxrows= $grid->{maxrows};
  return 0  unless defined($maxrows);
  return $grid->{row}>= $maxrows;
}

sub grid_nextrow { my ($grid)= @_;
  $grid->{row}++;  $grid->{col}= 0;
}

# ------------------------------------------------------------------------

sub ctlrow {  my ($parent, $wide)= @_;
  $DB::single= 1  unless defined($parent);
  $wide= 1  unless defined($wide);
  my $bgcolor= 4;
  my $cr= grid($parent, 99, 1, $bgcolor, 0, $wide);
  $cr->{nottall}= 1;
  return $cr;
}

#-------------------------------------------------------------------------------

sub  trim { my $s = shift; $s =~ s/^\s+|\s+$//g; $s=~ s|\s+| |g;  return $s };

sub menu_button  {  my ($parent, $btext, $cmd, $fsz)= @_;
  $DB::single= 1  unless defined($parent);
  $fsz= 0  if $fsz< 0;
  my $font= gcore::choosefont($fsz);
  $btext= trim($btext);  #print "'$btext'\n";
  my $btn= $parent-> Button(-text=> $btext, -font=>$font, -command=> $cmd);
  $btn->{nottall}= 1;
  gcore::mypack($btn, $parent, 0);
  return $btn;
}

sub control_button  {  my ($parent, $btext, $cmd)= @_;
  $DB::single= 1  unless defined($parent);
  my $font= gcore::choosefont(0);  my $bgcolor= gcore::choosebgcolor(3);
  my $btn= $parent-> Button(-text=> $btext, -font=>$font, -background => $bgcolor, -command=> $cmd);
  $btn->{nottall}= 1;
  gcore::mypack($btn, $parent, 0);
  return $btn;
}

sub checkbox {  my ($parent, $btext, $var, $fsz)= @_;
  $DB::single= 1  unless defined($parent);
  my $font= gcore::choosefont($fsz);
  my $btn= $parent-> Checkbutton(-text=> $btext, -font=>$font, -variable=> $var);
  $btn->{nottall}= 1;
  gcore::mypack($btn, $parent, 0);
  return $btn;
}

sub optmenu { my ($parent, $var, $opts, $cmd, $fsz)= @_;
  $DB::single= 1  unless defined($parent);
  my $font= gcore::choosefont($fsz);
  my $menu = $parent->Optionmenu(-options => $opts, -font=>$font, -textvariable => $var, -command => $cmd );
  $menu->{nottall}= 1;
  gcore::mypack($menu, $parent, 0);
  return $menu;
}

sub optmenu_set { my ($menu, $var)= @_;
  # http://www.perlmonks.org/?node_id=742573
  $menu->configure( -textvariable => $var); # give it a prod.
}

sub entry  {  my ($parent, $wid, $val, $fsz, $clrbtn, $clipbtn)= @_;
  $DB::single= 1  unless defined($parent);
  $val= ''  unless defined($val);
  $clrbtn= 0  unless defined($clrbtn);
  $clipbtn= 0  unless defined($clipbtn);
  my $font= gcore::choosefont(-1);  $font= gcore::choosefont($fsz)  if $fsz>=1;
  if ($clrbtn or $clipbtn)  {  $parent= ctlrow($parent, 0);  }
  my $entry= $parent->Entry(-width=>$wid, -font=>$font);
  $btn->{nottall}= 1;
  gcore::mypack($entry, $parent, 0);
  if ($clrbtn) {  g::control_button($parent, 'Clr', [\&entry_clear, $entry]);  }
  if ($clipbtn) {  g::control_button($parent, 'Paste', [\&entry_paste, $entry]);  }
  entry_set($entry, $val);
  return $entry;
}

sub entry_clear  { my ($entry)= @_;
  g::entry_set($entry, '');
} 

sub entry_get { my ($entry)= @_;
  return $entry->get();
}

sub entry_paste { my ($entry)= @_;
  entry_set($entry, fromclip());
}

sub entry_set { my ($entry, $val)= @_;
  return  unless defined($entry);
  $entry->delete(0, 'end');  $entry->insert('end', $val);
}

sub cell  {  my ($parent)= @_;
  $DB::single= 1  unless defined($parent);
  my $c= $parent->Frame(-bg=> $gcore::clr{bg});
  $btn->{nottall}= 1;
  gcore::mypack($c, $parent, 0);
  return $c;
}

sub label  {  my ($parent, $text, $litecolor, $fsz)= @_;
  $DB::single= 1  unless defined($parent);
  my $bgcolor= gcore::choosebgcolor($litecolor);
  $fsz= 0  if $fsz< 0;
  my $font= gcore::choosefont($fsz);
  my $fgcolor= $gcore::clr{fg};  $fgcolor= 'black'  if $bgcolor eq 'lightgrey';
  my $l= $parent->Label(-text=>trim($text), -bg=> $bgcolor, -fg=> $fgcolor, -font=>$font);
  # straight pack() will hang...
  $l->{nottall}= 1;
  gcore::mypack($l, $parent, 0);
  return $l;
}

sub varlabel  {  my ($parent, $var, $wid, $fsz)= @_;
  $wid= 60  unless defined($wid);
  my $l= $parent->Label(-textvariable=> $var, -font=> gcore::choosefont($fsz), -width=>$wid);
  $l->{nottall}= 1;
  gcore::mypack($l, $parent, 1);
  $parent->{var}= $var;
  return $l;
}


#---------------------------------------------------------------------------------

# to build a selector pane that can be easily cleared, and has a non-scrolling control section:
sub halfscroller { my ($parent, $ctlrow)= @_;
  my $self= g::colframe($parent);
  if (defined($ctlrow) and $ctlrow>0)  {  $self->{ctlrow}= g::ctlrow($self); }
  my $itemscroller= $self->{itemscroller}= g::frame_scrolled($self);
  $self->{itemframe}= g::colframe($itemscroller, 1);
  return $self;
}

sub halfscroller_clear { my ($self)= @_;
  $self->{itemframe}->destroy  if defined($self->{itemframe});
  $self->{itemframe}= g::colframe($self->{itemscroller});
}


#--------------------------------------------------------------------

sub toclip { my ($text)= @_;
  if (!$onwindows)  {
    my $cmd = '|xclip -i -selection clipboard';
    my $r = open my $exe, $cmd or warn "Couldn't run `$cmd`: $!\n";
    binmode $exe, ":utf8";
    print $exe $text;
    close $exe or warn "Error closing `$cmd`: $!";
    return;
  }

  my $CLIP = Win32::Clipboard();
  $CLIP->Set($text);
}

sub fromclip { 
  if (!$onwindows)  {
    my $text= '';
    my $cmd = 'xclip -o -selection clipboard|';
    eval {
      local $SIG{ALRM} = sub { die "...fromclip timeout\n" };
      alarm(5);      my $r = open (my $exe, $cmd) or warn "Couldn't run `$cmd`: $!\n";
      binmode $exe, ":utf8";
      print "fromclip... ";      read ($exe, $text, 4000);      print " ...fromclip\n";
      close $exe or warn "Error closing `$cmd`: $!";
      alarm(0);
    };
    return $text;
  }

  my $CLIP = Win32::Clipboard();
  return $CLIP->Get();
}

#--------------------------------------------------

sub is_string_chinese { my ($str)= @_; 
  return $str =~ m/(\p{Han}+)/;
}

1;
