package pinewattr;
use Tk;
use myf::fattr; use mypitem;  use mytk::g;  use mypi::pieditattr;
@ISA = ('pieditattr');

#-----------------------------------------------------------------

sub btext { my ($self)=@_;
  return "+Attribute";
}

sub new { my ($class, $cargs, $aargs) = @_;
  my $self= $class->tabpane::new($cargs, $aargs);
  $self->{isnew}= 1;
  my $fitem= $self->{fitem};  $DB::single=1 unless defined($fitem);
  my $ikey= $self->{ikey}= $fitem->{key};
  my $fattr= $self->{fattr}= fattr->new({ikey=>$ikey});
  return $self;
}


1;

