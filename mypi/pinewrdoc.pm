package pinewrdoc;
use Tk;
use myf::frdoc;
use mytk::g;  use mytk::tabpane;
@ISA = ('tabpane');

#-----------------------------------------------------------------

sub btext { my ($self)=@_;
  return "+Link Doc";
}

sub init  {  my ($self)= @_;
  return  if defined($self->{frdoc}); # idempotent
  print "pinewrdoc::init\n";
  my $fitem= $self->{fitem};
  my $key= $self->{key}= $fitem->{key};
}
  
sub populate {  my ($self)= @_;
  $self->init();
  my $w= $self->{window};
  my $key= $self->{key};
  my $frdoc= $self->{frdoc}= frdoc->new({key=>$key});

  my $cr= g::ctlrow($w);
  g::menu_button($cr, 'Save', [\&save, $self]);

  my $wid= 80;
  $w->{spec}= g::entry($cr, $wid, undef, 1,1,1);
  $self->fillfields();

  my $rdscroller= g::frame_scrolled($w);
  foreach my $spec (sort keys %frdoc::recentdocs)  {
    my $title= frdoc::fetchdoctitle($spec);
    my $btext= $title; $btext= substr($btext, 0, 80);
    next  if frdoc::relatedto($key, $spec);
    g::menu_button($rdscroller, $btext, [\&choosedoc, $self, $spec]);
  }
}

sub choosedoc { my ($self, $spec)= @_;
  my $w= $self->{window};  my $frdoc= $self->{frdoc};
  $frdoc->{spec}= $spec;  $self->fillfields();
}

sub fillfields { my ($self)= @_;
  my $frdoc= $self->{frdoc};
  my $w= $self->{window};
  my $spec= $w->{spec};  g::entry_set($spec, $frdoc->{spec})  if defined($spec);
}

sub save  { my ($self)= @_;
  g::timer_reset();
  my $frdoc= $self->{frdoc};
  $frdoc->{spec}= g::entry_get($self->{window}->{spec});
  $frdoc->readfields();
  $frdoc->title();
  #print "pinewrdoc::save frdoc spec= $frdoc->{spec}\n";
  $frdoc->save();
  mypitem::gdoswcmd('pimain');
}

1;

