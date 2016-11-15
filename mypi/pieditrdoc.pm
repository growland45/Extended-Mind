package pieditrdoc;
use Tk;
use myf::frdoc; use mypitem;  use mypeditrdoc;  use mytk::g;
@ISA = ('mypeditrdoc');

#-----------------------------------------------------------------

sub btext { my ($self)=@_;
  return "Edit Related Doc";
}

sub launch  {  my ($self, $key, $spec)= @_;
  my $frdoc= $self->SUPER::launch($spec);
  #print "pinewrdoc::launch key='$key'\n";
  $frdoc->{key}= $key;  $self->{key}= $key;
  $self->{fitem}= $self->{pimain}->{fitem};
}

  
sub populate {  my ($self)= @_;
  $self->SUPER::populate();
  my $w= $self->{window};  my $cr= $w->{cr};
  g::menu_button($cr, 'Disassociate', [\&g_delete, $self]);
}

sub g_save  { my ($self)= @_;
  $self->SUPER::g_save();
  $mypitem::fitem->choose_maindoc();
  mypitem::gdoswcmd('pimain');
}

sub g_delete  { my ($self)= @_;
  $self->{frdoc}->delentry();
  $mypitem::fitem->choose_maindoc();
  mypitem::gdoswcmd('pimain');
}

1;

