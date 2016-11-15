package records_cheap;
use utf8;
use Encode;
use mytk::g;  use mytk::records;
@ISA = ('records');



sub new { my ($class, $parent, $fields, $fmt) = @_;
  $fmt= "%s"  unless defined($fmt);
  my $self= bless {  }, $class;
  $cheap= 0  unless defined($cheap);
  $self->{fields}= $fields;
  $self->{cheap}= 1;
  $self->{fmt}= $fmt;
  my $pane= $self->{pane}= g::grid($parent, 1);  $fsz= 1;
  my @f= @$fields;
  my $s= sprintf($fmt, $f[0], $f[1], $f[2], $f[3], $f[4]);
  g::label($pane, $s, 1, $fsz);
  g::grid_nextrow($self->{pane});
  return $self;
}

sub addrec { my ($self, $rec)= @_;
  my $pane= $self->{pane};
  my $fields= $self->{fields};  my @f= @$fields;
  my $s= sprintf($self->{fmt}, 
                 $rec->{$f[0]}, $rec->{$f[1]}, $rec->{$f[2]}, $rec->{$f[3]}, $rec->{$f[4]});
  my $fsz= $self->{fsz};
  if (!defined($fsz))  { $fsz= 1;  $fsz= 3  if g::is_string_chinese($text); }
  g::label($self->{pane}, $s, 1, $fsz);
  g::grid_nextrow($pane);
}


1;

