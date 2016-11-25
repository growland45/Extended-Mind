package mypempties;
use Tk;
use myf::f;  use myf::fitem;  use myf::fsecentry;
use mytk::g;  use mytk::tabpane;
@ISA = ('tabpane');

sub btext { my ($self)=@_;
  return 'Todo';
}

sub populate  { my ($self)= @_;
  my $w= $self->{window};
  my $scroller= g::frame_scrolled($w);
  #print "gui_isearchsections...\n";
  my %l= ();
  fsecentry::f_searchwriteups(\%l, 10);
  fsecentry::f_searchempties(\%l, 20);
  fsecentry::f_searchtodo(\%l);
  main::g_popgrid($scroller, \%l, 1, 2);
}

1;

