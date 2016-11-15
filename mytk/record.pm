package record;
use utf8;
use Encode;
#use Clipboard;
use mytk::g;  use mytk::tp;

sub new { my ($class,
              $parent, $rec, $fields, $nkey1, $nkey2, $edit) = @_;
  my $self= bless {  }, $class;
  my $pane= $self->{pane}= g::colframe($parent);
  $self->{rec}= $rec;  $self->{edit}= $edit;
  $self->makerow($nkey1, 0);  $self->{nkey1}= $nkey1;
  $self->makerow($nkey2, 0);  $self->{nkey2}= $nkey2;
  foreach my $field (@$fields)  {
    $cr= $self->makerow($field, $edit);
  }
  $self->{fields}= $fields;
  g::menu_button($cr, 'Clip', [\&clipcopy, $self]);
  return $self;
}

sub destroy { my ($self)= @_;
  return  unless defined $self->{pane};
  $self->{pane}->destroy();
  $self->{pane}= undef;
}

sub makerow { my ($self, $fname, $edit)= @_;
  $edit = $self->{edit}  unless defined($edit);
  return  undef  unless defined($fname);
  my $pane= $self->{pane};
  $self->{$fname}= $self->{rec}->{$fname};
  if ($edit)  {
    g::label($pane, $fname);  tp::tpmake($pane, \$self->{$fname}, 70, 3);
    return $cr;
  }
  my $cr= g::ctlrow($self->{pane});
  g::label($cr, $fname);
  #print "makerow '$fname' '". $self->{$fname}. "'\n";
  g::varlabel($cr, \$self->{$fname}, 70);
  return $cr;
}

sub clipcopy  { my ($self)= @_;
  my $text= '';  my $fields= $self->{fields};
  my $nkey1= $self->{nkey1};  if (defined($nkey1))  { $text.= $self->{$nkey1}."\n"; }
  my $nkey2= $self->{nkey2};  if (defined($nkey2))  { $text.= $self->{$nkey2}."\n"; }
  foreach my $field (@$fields)  {    $text.= $self->{$field}."\n";  }
  #Clipboard->copy(Encode::decode_utf8($text));
  g::toclip($text);
}

1;

