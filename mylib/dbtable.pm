package dbtable;
use mylib::db;  use mylib::rec;
use DBI;

our $onwindows= int($^O eq 'MSWin32');
$debug= 0;  $debug= 1  if $onwindows;

sub new { my ($class, $tname, $dbh, $nkey1, $nkey2) = @_;
  my $self= bless {  }, $class;
  $dbh= $db::dbh  unless defined($dbh);
  $self->{tname}= $tname;  $self->{dbh}= $dbh;
  $self->{nkey1}= $nkey1;  $self->{nkey2}= $nkey2;
  $self->{inited}= 0;
  $self->init();
  return $self;
}

sub setfields { my ($self, @fields)=@_;
  #foreach my $f (@fields)  { print " [$f] ";}  print "\n";
  $self->{fields}= \@fields;
}


sub init  { my ($self)= @_;
}

sub create_table  { my ($self, $schema)= @_;
  return  if $self->table_exists();
  my $name= $self->{tname};
  die "dbtable::create_table no dbh\n"  unless defined($self->{dbh});
  print "CREATED TABLE $name\n"  if  execer($self->{dbh}, "CREATE TABLE if not exists $name ($schema);");
}

sub table_exists  { my ($self)= @_;
  die "dbtable::table_exists no dbh\n"  unless defined($self->{dbh});
  my $tname= $self->{tname};
  my $sql= "SELECT * FROM sqlite_master WHERE type='table' AND name='$tname'";
  my $sth = $self->{dbh}->prepare($sql);
  my $rec;
  unless (_rpterr($sth, $sql))  {
    $sth->execute();
    $rec= fetchselect($sth, 1);
  }
  #print "TABLE $tname EXISTS\n"  if defined($rec);
  return defined($rec);
}

sub create_field  { my ($self, $name, $type)= @_;
  my $table= $self->{tname};
  execer($self->{dbh}, "ALTER TABLE $table ADD COLUMN $name $type;");
}

sub create_index { my ($self, $fields)= @_;
  my $table= $self->{tname};
  my $iname= $fields;  $iname=~ s|[\,\s]||iog;  $iname= 'i'. $iname;
#  execer($self->{dbh}, "CREATE INDEX IF NOT EXISTS $iname on $table ($fields)");
}

#-----------------------------------------------------------------------------

sub count { my ($self)= @_;
  my $sth= $self->prepselect("count('*')");
  my $rec= fetchselect($sth, 1);
  foreach my $key (keys (%$rec))  {  return $rec->{$key};  }
}

sub readrec  { my ($self, $selectlist, $key1, $key2)= @_;
  my $sth;
  if (defined($key2))  {
    my $nkey1= $self->{nkey1};  my $nkey2= $self->{nkey2};
    $sth= $self->prepselect_binds($selectlist, "$nkey1=? AND $nkey2=?", ($key1, $key2));
  }
  else  { $sth= prepselect_4readrec($self, $selectlist, $key1); }
  $db_rec= fetchselect($sth, 1);
  return undef  unless defined($db_rec);

  my $dbrec= rec->new($db_rec);
  my $nkey1= $self->{nkey1};
  if (defined($nkey1))  {
    my $sortkey= $dbrec->{$nkey1};
    $dbrec->set_sortkey($sortkey);  }
  return $dbrec;
}

sub prepselect_4readrec  { my ($self, $selectlist, $key1, $orderby)= @_;
  $nkey= $self->{nkey1};
  my $options= "$nkey=?";  $options.= " order by $orderby"  if defined($orderby);
  return $self->prepselect_binds($selectlist, $options, ($key1));
}


sub readrec_altindex  { my ($self, $selectlist, $nkey, $key)= @_;
  my $sth= $self->prepselect_binds($selectlist, "$nkey=?", ($key));
  $db_rec= fetchselect($sth, 1);
  return $db_rec;
}

sub recexists  { my ($self, $key1, $key2)= @_;
  $nkey1= $self->{nkey1};  $nkey2= $self->{nkey2};
  my $sth;
  if (defined($nkey2))  {
    $sth= $self->prepselect_binds($nkey1, "$nkey1=? and $nkey2=?", ($key1, $key2));
  }  else  {
    $sth= $self->prepselect_binds($nkey1, "$nkey1=?", ($key1));
  }
  $db_rec= fetchselect($sth, 1);
  return defined($db_rec);
}

sub setrec {  my ($self, $rec, $fields, $noid)= @_;
  $noid= 0  unless defined($noid);
  my $nkey1= $self->{nkey1};
  my $flist= '';
  my @binds;
  foreach my $field (@$fields)  {
    next  if $field eq $nkey1;
    next  if $noid and $field eq 'id'; # tends to be autoincrement  
    $flist.= "$field=?,";
    push @binds, $rec->{$field};
  }
  $flist=~ s|\,$||o;
  push @binds, $rec->{$nkey1};
  $self->exec_set($flist, @binds);
}

sub insertrec {  my ($self, $rec, $fields, $noid)= @_;
  # replace into
  $noid= 0  unless defined($noid);
  my $flist= '';  my $vlist= '';
  my @binds;
  foreach my $field (@$fields)  {
    next  if $noid and $field eq 'id'; # tends to be autoincrement  
    $flist.= "$field,";
    $vlist.= "?,";
    push @binds, $rec->{$field};  #print "insertrec $field= '$rec->{$field}'\n";
  }
  $flist=~ s|\,$||o;
  $vlist=~ s|\,$||o;
  $self->exec_insert($flist, $vlist, @binds);
}

sub increment { my ($self, $key1, $key2, $field)= @_;
  my $table= $self->{tname};
  $field= 'count'  unless defined($field);
  $nkey1= $self->{nkey1};  $nkey2= $self->{nkey2};
  if (defined ($key2))  {
    my $sql= "UPDATE $table SET $field=$field+1 WHERE $nkey1=? AND $nkey2=?";
    execer($self->{dbh}, $sql, ($key1, $key2));
  } else {
    execer($self->{dbh}, "UPDATE $table SET $field=$field+1 WHERE $nkey1=?", ($key1));
  }
}


sub prepselect  {  my ($self, $fields,  $options)= @_;
  my $table= $self->{tname};
  $fields= '*'  unless defined($fields);
  my $sql= "SELECT $fields FROM $table";
  if (defined($options))  { $sql= "$sql $options"; }
  $DB::single=1  unless defined($self->{dbh});
  my $sth = $self->{dbh}->prepare($sql);
  $sth->execute()  unless _rpterr($sth, $sql);
  return $sth;
}

sub _rpterr { my ($sth, $sql)= @_;
  return  0 if defined($sth);
  print "FAILED  $sql\n";
  $DB::single= 1;
  return 1;
}

sub prepselect_binds  {  my ($self, $fields, $where, @binds)= @_;
  my $table= $self->{tname};
  my $sql= "SELECT $fields FROM $table WHERE $where";
  #print "db::prepselect $sql \n";
  die "prepselect_binds $sql NO dbh\n"  unless defined($self->{dbh});
  my $sth = $self->{dbh}->prepare($sql);
  unless (_rpterr($sth, $sql))  {
    $sth->execute(@binds) or print "$sql: ". $sth->errstr. "\n";
  }
  return $sth;
}

sub prep_iterate { my ($self, $fields)= @_;
  $fields= '*' unless defined($fields);
  my $sth= $self->prepselect($fields);
  return $sth;
}

sub wipe  {  my ($self)= @_;
  my $table= $self->{tname};
  print "*** WIPING $table ****\n";
  my $sql= "DELETE FROM $table";
  execer($self->{dbh}, $sql);
  #$dbh->commit();
}


sub exec_delete  {  my ($self, $key1, $key2)= @_;
  my $table= $self->{tname};
  my $nkey1= $self->{nkey1};  my $nkey2= $self->{nkey2};
  my $sql;
  $sql= "DELETE FROM $table WHERE $nkey1=?";
  $sql.= " and $nkey2= ?"  if defined($key2);
  print "$sql\n"  if $debug> 0;
  my $sth = $self->{dbh}->prepare($sql);
  unless (_rpterr($sth, $sql))  {
    if (defined($key2))  {  $sth->execute($key1, $key2); }
    else  {  $sth->execute($key1); }
    $sth->finish();
  }
  $lastsql= $sql;
  #$dbh->commit();
}

sub exec_delete_wherebinds  {  my ($self, $whereclause, @binds)= @_;
  my $table= $self->{tname};
  my $sql= "DELETE FROM $table WHERE $whereclause";
  execer($self->{dbh}, $sql, @binds);
}

sub exec_delete_null  {  my ($self, $field)= @_;
  my $table= $self->{tname};
  my $sql= "DELETE FROM $table WHERE $field IS NULL or $field=''";
  my $sth = $self->{dbh}->prepare($sql);
  print "exec_delete_null FAIL: $sql\n"  unless defined($sth);
  $sth->execute();
  $sth->finish();
  $lastsql= $sql;
  #$dbh->commit();
}


sub exec_update  {  my ($self, $cmd, @binds)= @_;
  my $table= $self->{tname};
  my $sql= "UPDATE $table ". $cmd;
  print "$sql\n"  if $debug> 0;
  my $sth = $self->{dbh}->prepare($sql);
  unless (_rpterr($sth, $sql))  {
    $sth->execute(@binds);
    $sth->finish();
  }
  #$dbh->commit();
}

sub exec_set  {  my ($self, $varvals, @binds)= @_;
  my $table= $self->{tname};
  my $nkey1= $self->{nkey1};  my $nkey2= $self->{nkey2};
  my $sql= "UPDATE $table SET $varvals WHERE $nkey1=?";
  $sql.= " and $nkey2=?"  if defined($nkey2);
  execer($self->{dbh}, $sql, @binds);
}

sub exec_new  {  my ($self, $fields, $values, @binds)= @_;
  my $table= $self->{tname};
  my $sql= "INSERT INTO $table ($fields) VALUES ($values);";
  return execer($self->{dbh}, $sql, @binds);
}

sub exec_insert  {  my ($self, $fields, $values, @binds)= @_;
  die "dbtable::exec_insert no dbh\n"  unless defined($self->{dbh});
  my $table= $self->{tname};
  my $sql= "REPLACE INTO $table ($fields) VALUES ($values);";
  execer($self->{dbh}, $sql, @binds);
}

#===================================================================

sub execer { my ($dbh, $sql, @binds)= @_;
  print "execer $sql\n"  if $debug;
  my $sth= sthexecb($dbh, $sql, @binds);
  $sth->finish()  if defined($sth);
  $lastsql= $sql;
  return defined($sth);
}

sub sthexecb { my ($dbh, $sql, @binds)= @_;
  if (!defined(dbh))  {
    $DB::single = 1;
    die "dbtable::exec_insert no dbh\n";
  }
  my $sth = $dbh->prepare($sql);
  if (_rpterr($sth, $sql))  { return undef; }
  print "exececb $sql\n"  if $debug;
  if (!defined($sth->execute(@binds)))  {
    print "EXECUTE FAILED: $sql ";
    my $errstr= $sth->errstr;
    print " (ERROR: $errstr) ";
    foreach my $bind (@binds)  {  print "'$bind' ";  }
    print "\n";
    $DB::single= 1;
    return undef;
  }
  
  return $sth;
}

sub fetchselect  {  my ($sth, $finish)= @_;
  $DB::single = 1  unless defined($sth);
  $finish= 0  unless defined($finish);
  $db_rec= $sth->fetchrow_hashref();
  finishselect($sth)  if $finish;
  return $db_rec;
}

sub finishselect  {  my ($sth)= @_;  $sth->finish();  }

sub begin_transact { my ($self)= @_;
  execer($self->{dbh}, 'BEGIN TRANSACTION');
}

sub end_transact { my ($self)= @_;
  execer($self->{dbh}, 'END TRANSACTION');
}

1;

