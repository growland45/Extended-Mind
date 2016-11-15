package mrdocs;
use Tk;
use myf::fitem;  use myf::f;  use myf::frelate;
use mytk::g;  use mytk::section;
@ISA = ('section');


sub pop_body { my ($self, $body)= @_;
  #print "mrdocs::pop_body...\n";
  my $w= $body;
  my $rlinks= $self->{rlinks};
  my $fitem= $self->fitem();  my $name= $fitem->{name};  my $key= $fitem->{key};

  my $wide= $self->{wide};
  my $ncols= 1;  $ncols= 3  if $wide;

  if (!defined($self->{dangles}))  {  $self->{dangles}= f_fetchdangles($fitem);  }
  my $dangles= $self->{dangles};

  my $cnt= scalar(keys %$dangles);
  my $mfsz= 1;  $mfsz= 0  if $cnt> 7;  $self->{mfsz}= $mfsz;
  $bwid=45;  $bwid= 40  if $wide or $cnt> 2;  $self->{bwid}= $bwid;

  $self->{cnt}= 0;
  my $mgrid= $self->{mgrid}= g::grid($body, $ncols);
  rec::fldscpy($mgrid, $self, ('bwid', 'mfsz'));  $mgrid->{maxfsz}= 2;
  my $grid= $self->{grid}= g::grid($body, $ncols);
  rec::fldscpy($grid, $self, ('bwid', 'mfsz'));  $grid->{maxfsz}= 2;
  foreach my $rkey (sort keys %$dangles)  {
    #print "mrdocs:  '$rkey'\n";
    $self->_pop_dangle($dangles->{$rkey});
    $self->{cnt}++;
  }
  #print "...mrdocs::pop_body\n";
}

sub _pop_dangle  { my ($self, $dangle)= @_;
  my $grid= $self->{grid};
  my $ref= ref $dangle;
  if ($ref eq 'frdoc')  {  $self->_pop_frdoc($dangle, $grid);  }
  elsif ($ref eq 'fsecentry')  {  $self->_popnot($dangle, $grid);  }
  elsif ($ref eq 'frelate')  {
    $grid= $self->{mgrid}  if $dangle->{rtcat} eq 'M';
    $self->_pop_torelate($dangle, $grid);
  } elsif ($ref eq 'fattr')  { $self->_pop_fattr($dangle, $grid);  }
  else  {  print "_pop_dangle UNSUPPORTED REF $ref\n";  }
}

$rwid= 15;  $twid= 30;  

sub _pop_torelate  { my ($self, $frelate, $grid)= @_;
  my $maxfsz= $grid->{maxfsz};
  my $key1= $frelate->{key1};  my $key2= $frelate->{key2};
  my $fsz= $frelate->rank();  $fsz= $maxfsz  if $fsz> $maxfsz;
  my $q= substr($frelate->{desc}, 0, $rwid);
  my $cr= g::rowframe($grid);
  g::label($cr, '"', 0, 0);  #print "$q\n";
  g::control_button($cr, $q, 
                    main::glaunchswcmd('myprelate', $key1, $key2), 0);
  main::glaunchbutton($cr, substr($frelate->{name2}, 0, $twid- $fsz*2),
                        $key2, $fsz);
}

sub _pop_frdoc  { my ($self, $frdoc, $grid)= @_;
  #print "_pop_frdoc $frdoc->{spec}\n";
  my $maxfsz= $grid->{maxfsz};
  my $fsz= $grid->{mfsz}+ $frdoc->rank();  $fsz= $maxfsz  if $fsz> $maxfsz;
  my $bwid= $grid->{bwid};  $bwid-= $fsz*2;
  my $cr= g::rowframe($grid);
  g::control_button($cr, 'E', [\&_launch_editrdoc, $self, $frdoc->{spec}]);

  my $title= $frdoc->btntitle($bwid);
  g::menu_button($cr, $title, [\&frdoc::launchspec, $frdoc->{spec}], $fsz);
}

sub _pop_fattr  { my ($self, $fattr, $grid)= @_;
  #print "_pop_frdoc $frdoc->{spec}\n";
  my $fsz= 1;
  my $bwid= $grid->{bwid};  $bwid-= $fsz*2;
  my $cr= g::rowframe($grid);
  #print "_pop_fattr id=$fattr->{id} type=$fattr->{type}\n";
  g::control_button($cr, 'E', [\&_launch_editattr, $self, $fattr->{id}]);

  g::label($cr, $fattr->{type}. ':', $fsz);
  g::label($cr, substr($fattr->{value}, 0, $bwid), 5, $fsz);
}

sub _popnot  { my ($self, $not, $grid)= @_;
  my $pitem= $self->{pimain}->{pitem};
  $pitem->pop_not($not, $grid);
}


sub f_fetchdangles  { my ($fitem)= @_;
  my %dangles;
  $fitem->get_rdocs(\%dangles);
  $fitem->get_attrs(\%dangles);
  $fitem->get_sectionlist('notes', \%dangles);
  frelate::get_torelates($fitem->{key}, \%dangles);
  return \%dangles;
}

sub fitem { my ($self)= @_;
  my $pimain= $self->{pimain};
  return $pimain->{fitem};
}

sub _launch_editrdoc { my ($self, $spec)= @_;
  mypitem::gdoswcmd('pieditrdoc', $spec);
}

sub _launch_editattr { my ($self, $id)= @_;
  #print "_launch_editattr id=$id\n";
  mypitem::gdoswcmd('pieditattr', $id);
}

1;

