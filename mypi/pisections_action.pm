package pisections_action;
use Tk;
use myf::fitem;  use mypitem;  use myf::fsecentry;
use mytk::g;
use mypi::msecentry;
@ISA = ('pisections');

sub new { my ($class, $cargs, $aargs) = @_;
  my $self= $class->SUPER::new($cargs, $aargs);
  $self->{isaction}= 1;
  $self->{type}= 'log';
  return $self;
}

sub btext { my ($self)= @_;  return 'Action';  }

sub typeslist { my ($self)= @_;  return \@fsecentry::actiontypes;  }

1;


