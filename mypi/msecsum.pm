package msecsum;
use Tk;
use mytk::g;  use mytk::section;
use mypitem;
@ISA = ('section');

$twid=30;

sub pop_body { my ($self, $body)= @_;
  #print "mrdocs::pop_body...\n";
  $mfsz= 0;  $mfsz= 1  if $self->{wide};  $self->{mfsz}= $mfsz;

  my $pimain= $self->{pimain};
  my $fitem= $pimain->{fitem};

  my $twopanes= g::rowframe($body);
  my $lpane= g::colframe($twopanes);

  my $rpane= g::colframe($twopanes);
  $self->{cnt}= 0;
  $self->_popsectype($rpane, 'writeup', 'Writeups');
  $self->_popsectype($rpane, 'log', 'Log entries');
  $self->_popsectype($rpane, 'thoughts', 'Thoughts');
}

sub _popsectype  { my ($self, $rpane, $sec, $label)= @_;
  my $pimain= $self->{pimain};
  my $fitem= $pimain->{fitem};
  my %secs=();  $fitem->get_sectionlist($sec, \%secs);
  my $cnt= scalar(%secs);
  if ($cnt> 0)  {
    my $ncols= 2;  $ncols= 5  if $self->{wide};
    my $grid= g::grid($rpane, $ncols);
    g::label($grid, $label, undef, 2);
    $self->_popnots(\%secs, $grid);
  }
  $self->{cnt}+= $cnt;
  return $cnt;
}

sub _popnots  { my ($self, $hnot, $grid)= @_;
  $grid->{mfsz}= 0;  $grid->{maxfsz}= 1;  $grid->{bwid}= $twid;
  my $pitem= $self->{pimain}->{pitem};
  foreach my $key (sort keys %$hnot)  {
    $pitem->pop_not($hnot->{$key}, $grid);
  }
}

1;


