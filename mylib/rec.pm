package rec;

sub new { my ($class, $args) = @_;
  my $self= bless {  }, $class;
  if (defined($args))  {
    foreach my $key (keys %$args)  { $self->{$key}= $args->{$key}; }
  }
  return $self;
}

sub sortkey  { my ($self)= @_;  return $self->{'___sortkey'};  }
sub set_sortkey  { my ($self, $key)= @_;  $self->{'___sortkey'}= $key;  }
sub rank  { my ($self)= @_;  return recdflt($self, 'importance', 1);  }
sub hashkey_trs  { my ($self, $typerank, $sortkey)= @_;
  $typerank= 0  unless defined($typerank);
  my $n= $self->rank()*13 + $typerank*7; # primes avoid collisions
  return (99999-$n). $sortkey;
}
sub hashkey  { my ($self, $typerank)= @_;  return $self->hashkey_trs($typerank, $self->sortkey());  }
sub hash_insert { my ($self, $hash)= @_;
  my $hkey= $self->hashkey(0);
  #print "rec::hash_insert '$hkey' importance=$self->{importance}\n";
  $hash->{$hkey}= $self;
}


#--------------- utils -------------------

sub recdflt { my ($rec, $field, $dflt)= @_;
  my $rv= $rec->{$field};
  $rv= $dflt  if (!defined($rv))  or $rv eq '';
  return $rv;
}

sub filldflt { my ($rec, $field, $dflt)= @_;
  my $rv= $rec->{$field};
  return $rv  if defined($rv) and $rv ne '';
  $rec->{$field}= $dflt;
  return $dflt;
}

sub fldcpy { my ($rec, $srec, $field, $dflt)= @_;
  filldflt($rec, $field, $dflt);
  return  unless defined($srec);
  my $val= $srec->{$field};
  return  unless defined($val);
  $rec->{$field}= $val;
  #print "fldcpy $field- '$val'\n";
}

sub fldscpy { my ($rec, $srec, @fields)= @_;
  return  unless defined($srec);
  foreach my $field (@fields)  {
    my $val= $srec->{$field};
    #print " [$field]  ";
    next  unless defined($val);
    $rec->{$field}= $val;
  }
  #print "\n";
}

sub fldscpyr { my ($rec, $srec, $fields)= @_;
  return  unless defined($srec);
  foreach my $field (@$fields)  {
    my $val= $srec->{$field};
    #print " [$field]  ";
    next  unless defined($val);
    $rec->{$field}= $val;
  }
  #print "\n";
}

sub recdump { my ($rec)= @_;  # TODO Data::Dumper?
  my $ref= ref $rec;
  print "recdump $rec ref='$ref'\n";
  foreach $key (sort keys %$rec)  {
    my $val= $rec->{$key};
    print "$key => '$val'\n"; 
  }
  print "\n";
}

1;

