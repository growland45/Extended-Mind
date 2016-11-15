package fsecentry;
use mylib::db;  use mylib::dbtable;  use mylib::dbrec;
use Date::Format;
@ISA = ('dbrec');

our $tsec= undef;
our $tsecid= undef;

@timelesstypes= ('notes', 'thoughts', 'questions', 'writeup');
@actiontypes= ('date', 'log', 'todo', 'wait');


sub init  {
  return if defined($tsec);
  return unless defined($db::dbh);
  # new style sections...
  $tsec= dbtable->new('isection', undef, 'ikey', 'type');
  $tsecid= dbtable->new('isection', undef, 'id');
  $tsec->setfields('id', 'ikey', 'type', 'importance', 'title', 'body');
  $tsec->create_table('id integer primary key autoincrement, ikey text not null, '.
                       'type text not null, importance integer, title text, body text');
  $tsec->create_index('ikey, type');
  $tsec->create_index('ikey, type, title');
  my $count= $tsec->count();  print "Total section entries: $count\n";
}

sub new { my ($class, $args) = @_;
  init();
  return $class->SUPER::new($args, $tsec);
}

sub delentry { my ($self)= @_;
  $tsecid->exec_delete($self->{id});
}

sub fetch_byid  {  my ($id)= @_;
  init();
  #print "fsecentry::fetch_byid('$id')\n";
  my $rec= $tsecid->readrec("*", $id);
  return undef  unless defined($rec);
  rec::filldflt($rec, 'importance', 1);
  my $srec= fsecentry->new($rec);
  #print "srec title= '$srec->{title}'\n";
  return $srec;
}

sub save { my ($self)= @_;
  init();
  #print "update_section ikey='$ikey' type='$type'\n";
  $tsecid->exec_insert('id, ikey, type, title, body, importance', '?,?,?,?,?,?',
        ($self->{id}, $self->{ikey}, $self->{type}, $self->{title}, $self->{body}, $self->{importance}) );
}

sub rank  { my ($self)= @_;
  return 1  if $self->{type} eq 'date';
  return $self->SUPER::rank();
}

sub sortkey  { my ($self)= @_;
   return substr($self->{title}, 0, 30). $self->{id};
}

sub isactiontype  { my ($self)= @_;
  return f_isactiontype($self->{type});
}

#------------------------------------------------------------

sub f_isactiontype { my ($type)= @_;
  foreach my $t (@actiontypes)  {
    return 1  if $type eq $t;
  }
  return 0;
}

#-------------------------------------------------------

sub f_search {  my ($list, $pattern, $max)= @_;
  init();
  $pattern1= $pattern. '%';
  $pattern2= '%'. $pattern. '%';
  my $sth= $tsec->prepselect_binds("ikey, type, id, title, importance",
            "title like ? or title like ? OR body like ?",
            ($pattern1, $pattern2, $pattern2));
  _search_fetch($list, $sth, $max);
}

$ob= 'order by importance, title';
$sf= 'ikey, type, id, title, importance';

sub f_questions {  my ($list, $max)= @_;
  init();
  my $sth= $tsec->prepselect_binds($sf, "type='questions' $ob");
  _search_fetch($list, $sth, $max);
}

sub f_searchempties  { my ($list, $max)= @_;
  my $sth= $tsec->prepselect_binds($sf,
            "body like '' and (type like 'notes' or type like 'thoughts') $ob");
  _search_fetch($list, $sth, $max);
}

sub f_searchwriteups  { my ($list, $max)= @_;
  my $sth= $tsec->prepselect_binds($sf,
            "(type like 'writeup' and body like '') or title like '%*' $ob");
  _search_fetch($list, $sth, $max);
}

sub f_searchtodo  { my ($list, $max)= @_;
  my $sth= $tsec->prepselect_binds($sf, "type like 'todo' $ob");
  _search_fetch($list, $sth, $max);
}

sub f_searchdates  { my ($list, $max)= @_;
  my $sth= $tsec->prepselect_binds($sf, "type like 'date' $ob");
  _search_fetch($list, $sth, $max);
}

sub f_searchwait  { my ($list, $max)= @_;
  my $sth= $tsec->prepselect_binds($sf, "type like 'wait' $ob");
  _search_fetch($list, $sth, $max);
}

sub _search_fetch { my ($list, $sth, $max)= @_;
  $max= 100  unless defined($max);  my $cnt= 0;
  while (my $rec= dbtable::fetchselect($sth))  {
    my $fse= fsecentry->new($rec);
    $fse->hash_insert($list);
    $cnt++;
    last  if $cnt>= $max;
  }
  dbtable::finishselect($sth);
}

#-----------------------------------------------------------------

sub prune_sections  {
  $tsec->exec_delete_null('title');
}


sub f_sectionexists {  my ($key, $section)= @_;
  return $tsec->recexists($key, $section);
}

sub f_getsectionlist { my ($key, $type, $hash)= @_;
  init();
  #print "fsecentry::f_getsectionlist(key=$key, type=$type)\n";
  my $sth= $tsec->prepselect_binds('id, title, importance, length(body) as lb',
                                   "ikey=? and type=?", ($key,$type));
  while (my $srec= dbtable::fetchselect($sth))  {
    #print "   f_getsectionlist, srec=$srec\n";
    my $fse= fsecentry->new($srec);
    $fse->hash_insert($hash);
  }
  dbtable::finishselect($sth);
}

sub f_hassecentries { my ($key)= @_;
  init();
  my $sth= $tsec->prepselect_binds('id', "ikey=?", ($key));
  my $srec= dbtable::fetchselect($sth);
  dbtable::finishselect($sth);
  return defined($srec);
}

sub f_newsecentry { my ($key, $type, $tempname)= @_;
  init();
  my $body= '';
  if (!defined($tempname))  {
    $tempname= "New entry $key '$type'";
  }
  if ($type eq 'date')  {
    $tempname=  time2str('%Y-xx-xx ', time);
  }
  if ($type eq 'log')  {
    $tempname=  time2str("%Y-%m... $key", time);
    $body=  time2str('%Y-%m-%d ', time);
  }

  $tsec->exec_insert('ikey, type, title, body, importance', '?,?,?,?,1',
        ($key, $type, $tempname, $body) );
        
  #all this just to return the id...
  my $sth= $tsec->prepselect_binds('id', "ikey=? AND title=?", ($key, $tempname));
  my $rec= dbtable::fetchselect($sth, 1);
  return $rec->{id};
}

1;
