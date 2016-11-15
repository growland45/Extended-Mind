package fattr;
use mylib::db;  use mylib::dbtable;  use mylib::dbrec;
@ISA = ('dbrec');

our $ta= undef, $tai= undef;

sub init  {
  return if defined($ta);
  return unless defined($db::dbh);
  $ta= dbtable->new('attr', undef, 'id');
  $ta->setfields('id', 'ikey', 'type', 'value');
  $ta->create_table('id integer primary key autoincrement, ikey text, type text, value text');
  $ta->create_index('ikey');
  my $count= $ta->count();  print "Total attributes: $count\n";
}

sub new { my ($class, $args) = @_;
  init();
  return $class->SUPER::new($args, $ta);
}

sub newentry  {  my ($self, $ikey, $type)= @_;
  init();
  $self->{ikey}= $ikey;  $self->{type}= $type;
  $self->{value}= '';
  $self->save(1);
}

sub delentry  { my ($self)= @_;
  $ta->exec_delete($self->{id});
}

sub hashkey  { my ($self, $typerank)= @_;  return $self->hashkey_trs(4, $self->sortkey());  }

sub sortkey  { my ($self)= @_;  return $self->{type}. $self->{value};  }


sub get_attrs { my ($key, $hash)= @_;
  init();
  my $sth= $ta->prepselect_binds("*", "ikey=?", ($key));
  while (my $rec= dbtable::fetchselect($sth))  {
    my $fattr= fattr->new($rec);
    $fattr->hash_insert($hash);
  }
  dbtable::finishselect($sth);
}

1;
