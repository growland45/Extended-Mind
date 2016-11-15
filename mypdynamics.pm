package mypdynamics;
use Tk;
use myf::frdoc;
use mytk::g;  use mytk::tabpane;
@ISA = ('tabpane');

sub btext { my ($self)=@_;
  return 'Dynamics';
}

%dlist;


sub populate  { my ($self)= @_;
  my $w= $self->{window};

  my %sites;
  frdoc::get_scansites(\%sites);
  my $g= g::grid($w, 3);
  foreach my $key (sort keys %sites)  {
    my $fsite= $sites{$key};
    my $title= $fsite->{title};
    $title= $fsite->{spec}  unless defined($title);
    g::menu_button($g, substr($title, 0, 37), [\&gscansite, $fsite->{spec}], 2);
  }

  my $cr= g::ctlrow($w);
  g::label($cr, "Dynamic documents...", 5, 2);
  g::menu_button($cr, 'Random link', [\&glaunchrandom, \%dlist]);
  g::label($cr, f::get_thoughtprompt(), 5);
  my $scroller= g::frame_scrolled($w);
  %dlist= {};
  frdoc::search_dynamics(\%dlist);
  main::g_popsearchdocresults($scroller, \%dlist);
}

sub gscansite  { my ($spec)= @_;
  main::gdoswcmd('mypscansite', $spec);
}

sub glaunchrandom  {  my ($list)= @_;
  my $rec= frdoc::chooserandomdoc($list);
  return  unless defined($rec);
  my $spec= $rec->{spec};
  g::timer_reset();
  frdoc::launchspec($spec);
}



1;

