package mypperuses;
use Tk;
use myf::frdoc;
use mytk::g;  use mytk::tabpane;
@ISA = ('tabpane');

sub btext { my ($self)=@_;
  return 'Peruses';
}

%plist;


sub populate  { my ($self)= @_;
  my $w= $self->{window};
  my $cr= g::ctlrow($w);
  g::label($cr, "Peruse documents...", 5, 3);
  %plist= ();
  frdoc::search_peruses(\%plist);
  g::menu_button($cr, 'Random link', [\&glaunchrandom, \%plist]);
  g::label($cr, f::get_thoughtprompt(), 5);
  my $scroller= g::frame_scrolled($w);
  main::g_popsearchdocresults($scroller, \%plist);
}

sub glaunchrandom  {  my ($list)= @_;
  my $rec= frdoc::chooserandomdoc($list);
  return  unless defined($rec);
  my $spec= $rec->{spec};
  g::timer_reset();
  frdoc::launchspec($spec);
}



1;

