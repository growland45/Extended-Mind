package tabpane;
use mytk::g;
# works with tabrow

sub new { my ($class, $cargs, $aargs) = @_;
  my $self= bless {  }, $class;
  if (defined($cargs)) { foreach my $key (keys %$cargs)  { $self->{$key}= $cargs->{$key}; } }
  if (defined($aargs)) { foreach my $key (keys %$aargs)  { $self->{$key}= $aargs->{$key}; } }
  return $self;
}

sub make  { my ($self)= @_;
  my $w= $self->{window}= g::colframe($self->{mainpanel}, undef, undef, 1);
  #print "tabpane::make w=$w\n";
  $self->populate();
  g::timer_reset();
  return $w;
}

sub onleave { my ($self) = @_;
  $self->saveonleave();
  $self->destroy();
}

sub saveonleave { my ($self) = @_;
}

sub launch { my ($self) = @_;
}

sub populate { my ($self) = @_;
}

sub destroy { my ($self) = @_;
  return unless defined ($self->{window});
  $self->{window}->destroy();  undef $self->{window};
}

sub refresh { my ($self) = @_;
  $self->destroy();
  $self->make();
}

1;

