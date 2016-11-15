package gpalette;

@cablack= (0,0,0);
@cawhite= (1,1,1);
@cacolor= (0,1,1);

sub makecolor { my ($ra, $rb, $rc)= @_;
  my @rp= ($ra, $rb, $rc);
  my @c= mixcolors(\@cablack, \@cawhite, \@cacolor, \@rp); 
  return colorfromrgb($c[0], $c[1], $c[2]);
}

sub mixcolors { my ($aa, $ab, $ac, $p)= @_;
  my @ra= @$aa;  my @rb= @$ab;  my @rc= @$ac;  my @rp= @$p;
  #print "mixcolors ". $rp[0]. ' '. $rp[1]. ' '. $rp[2]. "\n";
  colornormalize(\@rp);
  #print "mixcolors tot=$tot ". $rp[0]. ' '. $rp[1]. ' '. $rp[2]. "\n";
  $ra[0]*= $rp[0];  $ra[1]*= $rp[0];  $ra[2]*= $rp[0];
  $rb[0]*= $rp[1];  $rb[1]*= $rp[1];  $rb[2]*= $rp[1];
  $rc[0]*= $rp[2];  $rc[1]*= $rp[2];  $rc[2]*= $rp[2];
  my @mix= (0,0,0);
  $mix[0]= $ra[0]+ $rb[0]+ $rc[0]; 
  $mix[1]= $ra[1]+ $rb[1]+ $rc[1]; 
  $mix[2]= $ra[2]+ $rb[2]+ $rc[2];
  return @mix; 
}

sub colornormalize { my ($a)= @_;
  my $tot= 1.0* $a->[0]+ $a->[1]+ $a->[2];
  return if $tot< 0.000001;
  $a->[0]/= $tot;  $a->[1]/= $tot;  $a->[2]/= $tot;
}

sub colorfromrgb { my ($r, $g, $b)= @_;
  #print "colorfromrgb($r, $g, $b)\n";
  $r= int($r*15.0);  $g= int($g*15.0);  $b= int($b*15.0);
  my $c= sprintf ('#%x%x%x%x%x%x', $r,$r,$g,$g,$b,$b); #print "$c\n";
  return $c;
}

sub make  { my ($newclr)= @_;
  @cacolor= @$newclr  if defined($newclr);
  %clr= (bg=>   makecolor(10, 0,4),
         bg1=>  makecolor(9, 1,6),
         bg2=>  makecolor(8, 2,7),
         bg3=>  makecolor(5, 5,5),
         dgr=>  'darkgrey',
         fg=>   'white');
  return %clr;
}


1;

