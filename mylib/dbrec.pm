package dbrec;
use mylib::rec;
@ISA = ('rec');
#persistent object

sub new { my ($class, $args, $dbt) = @_;
  my($self)= $class->SUPER::new($args);
  $self->{_dbt}= $dbt;
  return $self;
}

sub readfields {  my ($self, $fields)= @_;
  my $dbt= $self->{_dbt};
  $fields= $dbt->{fields}  unless defined($fields);
  my $nkey1= $dbt->{nkey1},  $nkey2= $dbt->{nkey2};
  my $key1= $self->{$nkey1}, $key2= $self->{$nkey2};
  my $rec= $dbt->readrec('*', $key1, $key2);
  rec::fldscpyr($self, $rec, $fields)  if defined($rec);
  return $rec;
}

sub fields { my ($self)= @_;
  my $dbt= $self->{_dbt};
  return $dbt->{fields};
}

sub delete {  my ($self)= @_;
  my $dbt= $self->{_dbt};
  my $nkey1= $dbt->{nkey1},  $nkey2= $dbt->{nkey2};
  my $key1= $self->{$nkey1}, $key2= $self->{$nkey2};
  $dbt->exec_delete($key1, $key2);
}

sub save {  my ($self, $isnew, $noid)= @_;
  $isnew= 0  unless defined($isnew);
  my $dbt= $self->{_dbt};
  my $nkey1= $dbt->{nkey1};  $noid= 1  if $nkey1 eq 'id' and !defined($noid);
  if ($isnew)  {
    #$DB::single=1;
    $dbt->insertrec($self, $dbt->{fields}, $noid);
    my @idf= ['id'];  $self->readfields(\@idf)  if $nkey1 eq 'id';
  }
  else  {  $dbt->setrec($self, $dbt->{fields}, $noid);  }
}

sub foldin { my ($self, $tother, $nkey1, $nkey2)= @_;
  my $dbt= $self->{_dbt};
  $nkey1= $dbt->{nkey1}  unless defined($nkey1);
  my $key1= $self->{$nkey1}, $key2= $self->{$nkey2};
  my $rother= $tother->readrec('*', $key1, $key2);
  rec::fldscpyr($self, $rother, $tother->{fields})  if defined($rother);
  return $rother;
}


1;

