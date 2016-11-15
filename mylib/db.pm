package db;

$debug=0;

use DBI;
use Text::Metaphone;
#use Text::DoubleMetaphone qw( double_metaphone );

our $file;
our $dbh;

sub abbrev  {  my ($full)= @_;
  my $lcfull= lc($full);
  $lcfull=~ s| the ||og;  $lcfull=~ s| a ||og;  $lcfull=~ s| an ||og;  $lcfull=~ s| of ||og;
  $lcfull=~ s|\s||og;
  my $l= length($lcfull);
  if ($l<= 8)  {
    #print"abbrev('$full')= '$lcfull'\n";
    return $lcfull;
  }  
  # use Text::Metaphone;
  my $mf= Metaphone($full);
  my $last= substr($full, -1);
  if ($last=~m|\d|o)  { $mf.= $last; }
  my $chalf=4;
  my $abbrev= substr($mf, 0, $chalf);
  my $l= length($mf)- $chalf;  if ($l> $chalf)  { $l= $chalf; };
  if ($l> 0)  { $abbrev.= substr($mf, -$l); }
  $abbrev= lc($abbrev);
  #print "abbrev('$full') (MF) = '$abbrev'\n";
  return $abbrev;
}

sub init  {  my ($dbfile)= @_;
  print "db::init('$dbfile')\n";
  $file= $dbfile;
  reinit();
}

sub reinit  {
  $dbh= sqlite_open($file);
}

sub sqlite_open { my ($file)= @_;
  my $spec= "dbi:SQLite:dbname=$file";
  print "connect $spec\n";
  my $dbh = DBI->connect($spec, "","");
  print "FAILED connect $spec\n"  unless defined($dbh);
  $dbh->{sqlite_unicode} = 1;
  return $dbh;
}

sub deinit  {  return  unless defined($dbh);  $dbh->disconnect();  undef($dbh);  }

sub create_table { my ($name, $schema)= @_;
  db::exec("CREATE TABLE if not exists $name ($schema);");
}

sub launch_manager  {  my ($lfile, $suspend)= @_;
  $suspend= 1  unless defined($suspend);
  $lfile= $file  unless defined($lfile);
  my $cmd= "sqlitebrowser $lfile";
  print "EXEC: $cmd\n";
  if ($suspend)  {
    #deinit();
    system($cmd); # yes, we want to block
    #reinit();
  }  else  {
    system("$cmd &");
  }
}

sub fetchselect  {  my ($sth)= @_;  return $sth->fetchrow_hashref();  }

sub finishselect  {  my ($sth)= @_;  $sth->finish();  }

sub begin_transact {
  db::exec('BEGIN TRANSACTION');
}

sub end_transact {
  db::exec('END TRANSACTION');
}

sub exec { my ($sql, @binds)= @_;
  print "FAILED: NO DBH $sql\n"  unless defined($dbh);
  my $sth = $dbh->prepare($sql);
  print "FAILED: $sql\n"  unless defined($sth);
  $sth->execute(@binds);
  $sth->finish();
}


sub setdebug { my ($val)= @_;
  $debug= $val;
  print "db::setdebug -> $debug\n";
}

1;

