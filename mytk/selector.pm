package selector;
use mytk::g;

sub new { my ($class, $args) = @_;
  my $width= $args->{width};  $width= 23  unless defined($width);
  my $self= bless {  }, $class;

  my $frame= $self->{frame}= $args->{frame};
  my $tctlrow;
  my $selindic= $args->{selindic};  my $cbload= $args->{cbload};

  if (defined($cbload))  {
    $tctlrow= $self->{tctlrow}= g::ctlrow($frame);
    $height--;
    $self->{cbload}= $cbload;
    g::menu_button($tctlrow, 'Load', [\&loadbtncb, $self]);
  }
  if (defined($selindic))  {
    my $labeltext= '';
    $self->{labeltext}= \$labeltext;
    $self->{varlabel}= g::varlabel($frame, $self->{labeltext}, $width); 
    $height--;
  }

  my $cbnew= $args->{cbnew};
  if (defined($cbnew))  {
    my $bctlrow= $self->{bctlrow}= g::ctlrow($frame);
    my $wscratch= $self->{wscratch}= g::entry($bctlrow, $width-3);
    $bctlrow->{col}= 1;
    $self->{cbnew}= $cbnew;
    g::menu_button($bctlrow, 'New', [\&newbtncb, $self]);
  }

  my $itemscroller= $self->{itemscroller}= g::frame_scrolled($frame);
  $self->{itemframe}= g::colframe($itemscroller);

  return $self;
}

sub newbtncb { my ($self)= @_;
  #print "newbtncb($self)\n";
  my $newname= $self->{wscratch}->get();
  my $cbnew= $self->{cbnew};
  return unless  &$cbnew($newname);
  $self->insert($newname);
}

sub loadlist { my ($self, $keynamelist)= @_;
  $self->clear();
  foreach my $key (sort keys %$keynamelist) {
    my $name= $keynamelist->{$key};
    $self->insert($name, $key);
  }
}

sub clear  { my ($self)=@_;
  $self->{itemframe}->destroy  if defined($self->{itemframe});
  $self->{itemframe}= g::colframe($self->{itemscroller});
}

sub insert  { my ($self, $name, $key)= @_;
  my $itemframe= $self->{itemframe};
  #print "gselector::insert key='$key'\n";
  my $btn= g::menu_button($itemframe, $name, [\&btncb, $self, $name, $key]);
}

sub btncb { my ($self, $name, $key)= @_;
  #print "loadbtncb($self)\n";
  my $cbload= $self->{cbload};
  $$self->{labeltext}= $name  if defined($self->{labeltext});
  &$cbload($name, $key);
}

1;

