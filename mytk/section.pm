package section;
use mytk::g;

sub new { my ($class, $parent, $args) = @_;
  my $self= bless {  }, $class;
  $self->{parent}= $parent;
  if (defined($args)) { foreach my $key (keys %$args)  { $self->{$key}= $args->{$key}; } }
  $self->{scrolled}= 0  unless defined($self->{scrolled});
  $self->make();
  return $self;
}

sub make  { my ($self)= @_;
  my $w= $self->{window}= g::grid($self->{parent}, 1, undef, undef, 1, 1);
  $self->makectlrow();
  $self->makebody();
  return $w;
}

sub wantctlrow { my ($self)= @_;  return 0;  }

sub makectlrow  { my ($self)= @_;
  my $w= $self->{window};
  $w->{ctlrow}->destroy()  if defined ($w->{ctlrow}); # in case re-make
  $w->{ctlrow}= undef;
  if ($self->wantctlrow()) {
    $w->{ctlrow}= g::ctlrow($w, 1);
    $self->pop_ctlrow($w->{ctlrow});
  }
}

sub makebody  { my ($self)= @_;
  my $w= $self->{window};
  $w->{body}->destroy()  if defined ($w->{body}); # in case re-make
  $w->{body}= g::grid($w, 1, undef,undef, 0, 1);
  $self->pop_body($w->{body});
}

sub onleave { my ($self) = @_;
  $self->saveonleave();
  $self->destroy();
}

sub saveonleave { my ($self) = @_;
}

sub populate { my ($self) = @_;
  my $w= $self->{window};
  $self->pop_ctlrow($w->{ctlrow});
  $self->pop_body($w->{body});
}

sub pop_ctlrow  { my ($self, $ctlrow)= @_;
}

sub pop_body  { my ($self, $body)= @_;
}

sub destroy { my ($self) = @_;
  return unless defined ($self->{window});
  $self->{window}->destroy();  undef $self->{window};
}

sub refresh { my ($self) = @_;
  $self->makectlrow();
  $self->makebody();
}

1;

