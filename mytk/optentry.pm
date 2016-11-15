package optentry;
use Tk;  use utf8;
use mytk::g;  use mytk:gcore;

sub new { my ($class, $parent, $wid, $opts, $val, $fsz) = @_;
  my $self= bless {  }, $class;
  $self->{text}= '';
  my $font= gcore::choosefont(-1);  $font= gcore::choosefont($fsz)  if $fsz>1;
  my $cr= g::ctlrow($parent, 0);
  my $entry= $cr->Entry(-width=>$wid, -font=>$font);
  gcore::mypack($entry, $cr, 0);
  if ($opts->[0] ne '')  { g::menu_button($cr, 'Clr', [\&entry_clear, $entry]);  }
  if (defined($val)) { 
    g::entry_set($entry, $val);
    $self->{text}= $val;
  }
  $self->{cr}= $cr; $cr->{entry}= $entry;
  $self->add_optmenu($opts);
  return $self;
}

sub add_optmenu  { my ($self, $opts)= @_; # may want more than one
  g::optmenu($self->{cr}, \$self->{text}, $opts, [\&onselect, $self]);
}

sub destroy { my ($self) = @_;
  return unless defined ($self->{cr});
  $self->{cr}->destroy();  undef $self->{cr};
}


sub onselect  { my ($self)= @_;
  my $cr= $self->{cr};  my $entry= $cr->{entry};
  g::entry_set($entry, $self->{text});
}

sub entry_get { my ($self)= @_;
  my $cr= $self->{cr};  my $entry= $cr->{entry};
  return g::entry_get($entry);
}

sub entry_set { my ($self, $val)= @_;
  my $cr= $self->{cr};  my $entry= $cr->{entry};
  return  g::entry_set($entry, $val);
}

1;
