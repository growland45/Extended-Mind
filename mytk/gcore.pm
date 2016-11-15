package gcore;
use mytk::gpalette;
use Tk;  use Tk::Font;  use Tk::Pane;
use utf8;  use English;

our %clr, @fonts, $maxfont;

sub init_palette {  my ($newclr)= @_;
  %clr= gpalette::make($newclr);
}

sub init_fonts  {  my ($mw, $fam)= @_;
  # having a very hard time with Chinese characters on Debian 8.2...
  # many barf extra bad with large fonts size
  $fam= 'mincho'  unless defined($fam);  my $ff='courier';
  eval {
    $mw->fontCreate("$fam.small", -family => $fam, -size => 10);
    $mw->fontCreate("$fam.normal", -family => $fam, -size => 12);
    $mw->fontCreate("$fam.l1", -family => $fam, -weight=>'normal',-size => 14);
    $mw->fontCreate("$fam.l2", -family => $fam, -weight=>'normal', -size => 16);
    $mw->fontCreate("$fam.l3", -family => $fam, -weight=>'bold', -size => 18);
    $mw->fontCreate("$ff.fixed", -family => $ff, -size => 11);
  };
  $c_fontfixed= "$ff.fixed"; 
  @fonts= ("$fam.small", "$fam.normal", "$fam.l1", "$fam.l2", "$fam.l3");
  $maxfont= scalar(@fonts)-1;
}


sub frame { my ($parent, $litecolor, $scrolled, $border)= @_;
  $DB::single= 1  unless defined($parent);
  $scrolled= 0  unless defined($scrolled);
  $border= 0  unless defined($border);
  my $bgcolor= choosebgcolor($litecolor);
  my $f;
  if ($scrolled) {
    my $sb= 'oe';  $sb= 'osoe'  if $scrolled==2;
    $f= $parent->Scrolled('Pane', -scrollbars=>$sb, -height=>550, -sticky => "nsew");
  } else  {
    $f= $parent->Frame();
  }
  $f->configure(-bg=> $bgcolor);
  if ($border)  { $f->configure(-borderwidth=>1, -relief=>solid);  }
  mypack($f, $parent);
  #my $r= ref $f;  print "frame returns type ref='$r'\n";
  return $f;
}

sub mypack { my ($f, $parent, $expand)= @_;
  $nottall= $f->{nottall}; $nottall= 0  unless defined($nottall);
  $pos= $parent->{pos};
  #print "mypack inserting $f, parent=$parent pos='$pos')\n";
  $expand= $f->{expand}  unless defined($expand);
  $expand= 1  unless defined($expand);
  return mypack_grid($f, $parent, $expand)  if ($pos eq 'grid');

  my $fill= 'none'; $fill= 'x'  if  $f->{wide};
  $expand= 0  if $nottall; # -expand does both x and y, no helping it
  if ($expand== 1)  {  $fill= 'both';  $fill= 'x'  if $nottall;  }

  my %a= (-side=>'left', -anchor => 'nw',
          -pady=>2, -fill=>$fill, -expand=>$expand);
  if ($pos eq 'l2r')  { $f->pack(%a); } # rowframe
  else  { $a{'-side'}= 'top';    $f->pack(%a); }
}

sub mypack_grid { my ($f, $parent, $expand)= @_;
  my $cols= $parent->{cols};
  my $col= $parent->{col};  my $row= $parent->{row};
  my %a= (-row => $row, -column => $col, -padx=>2, -pady=>2, -sticky=>'nw');
  $a{'-sticky'}= 'new'  if $expand or $f->{wide};
  $f-> grid(%a);
  #print "mypack_grid inserting $f, row=$row col=$col (cols=$cols maxrows=$maxrows parent=$parent)\n";
  $parent->gridColumnconfigure(0, -weight=> 1)  if $cols== 1;
  $parent->gridColumnconfigure($col, -weight=> 1)  if $f->{wide}  or  $parent->{wide};
  $col++;  if ($col>= $cols)  { $col= 0;  $row++; }
  $parent->{col}= $col;  $parent->{row}= $row;
}

sub choosebgcolor { my ($litecolor)= @_;
  my $bgcolor= $clr{bg};
  $litecolor= 0  unless defined($litecolor);
  $bgcolor= $clr{bg1}  if $litecolor==1;
  $bgcolor= $clr{bg2}  if $litecolor==2;
  $bgcolor= $clr{bg3}  if $litecolor==3;
  $bgcolor= 'darkgrey'  if $litecolor==4;
  $bgcolor= 'lightgrey' if $litecolor==5;
  return $bgcolor;
}

sub choosefont { my ($fsz, $max)= @_;
  $fsz= 1  unless defined($fsz);
  $fsz= $max  if defined($max)  and $max< $fsz;
  return $c_fontfixed  if $fsz< 0;
  $fsz= $maxfont  if $fsz> $maxfont;
  return $fonts[$fsz];
}

1;

