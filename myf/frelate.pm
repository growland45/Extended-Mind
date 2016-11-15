package frelate;
use mylib::db;  use mylib::dbtable;  use mylib::dbrec;
use myf::f;
@ISA = ('dbrec');

our $trelate= undef;

sub init  {
  return if defined($trelate);
  return unless defined($db::dbh);
  $trelate= dbtable->new('relation', undef, 'key1', 'key2');
  $trelate->setfields('key1', 'key2', 'desc', 'body');
  $trelate->create_table(
      'key1 text not null, key2 text not null, desc text, body text, PRIMARY KEY(key1, key2)');
  my $count= $trelate->count();  print "Total relations: $count\n";

  $trel= dbtable->new('relatetypes', undef, 'reltype');
  $trel->setfields('reltype', 'rtcat');
  $trel->create_table('reltype text unique, rtcat text');
  if ($trel->count()== 0)  {
    _rt('a kind of', 'M');
    _rt('about', 'P');
    _rt('aspect of', 'M');
    _rt('by', 'P');
    _rt('category of', 'M');
    _rt('concept in', 'M');
    _rt('employed by', 'A');
    _rt('enables', 'A');
    _rt('is a', 'M');
    _rt('opposes', 'A');
    _rt('opposite of', 'P');
    _rt('requires', 'A');
    _rt('relevant to', 'P');
    _rt('result of', 'A');
    _rt('similar to', 'P');
  }
}

sub _rt { my ($reltype, $rtcat)= @_;
  my %rec; $rec{reltype}= $reltype;  $rec{rtcat}= $rtcat; 
  $trel->insertrec(\%rec, ['reltype', 'rtcat']);
}

sub new { my ($class, $args) = @_;
  init();
  my $self= $class->SUPER::new($args, $trelate);
  rec::filldflt($self, 'desc', '');
  rec::filldflt($self, 'body', '');
  return $self;
}

sub readfields  {  my ($self)= @_;
  init();
  my $rec= $self->SUPER::readfields();
  return 0 unless defined($rec);
  $self->readnames();
  return 1;
}

sub readnames  {  my ($self)= @_;
  my $key1= $self->{key1};  my $key2= $self->{key2};
  #print "frelate::readnames key1=$key1, key2=$key2\n";
  $self->{name1}= f::itemnamefromkey($key1);
  $self->{name2}= f::itemnamefromkey($key2);
  #print "frelate::readnames $self->{name1}, $self->{name2}\n";
}

sub save  { my ($self)= @_;
  init();
  #print "frelate::save()\n";
  $trelate->exec_set("desc= ?, body = ?", ($self->{desc}, $self->{body}, 
                       $self->{key1}, $self->{key2}));
}

sub newentry  {  my ($self)= @_;
  init();
  $trelate->exec_insert("key1, key2, desc, body", "?,?,?,?",
                        ($self->{key1}, $self->{key2}, $self->{desc}, $self->{body}));
}

sub delentry  { my ($self)=@_;
  init();
  $trelate->exec_delete($self->{key1}, $self->{key2});
}

#------------------------------------------------------------------------------

sub f_getreltypelist  {
  %f_reltypes= ();  $f_reltypes{''}= '';
  $DB::single=1  unless defined($trel);
  my $sth = $trel->prepselect();
  while (my $rec= dbtable::fetchselect($sth))  {
    my $reltype= $rec->{'reltype'};
    $f_reltypes{$reltype}= $rec;
  }
  dbtable::finishselect($sth);
  return \%f_reltypes;
}

sub reltypelist  {
  return \%f_reltypes;
}


#------------------------------------------------------------------------------

sub get_torelates  { my ($key, $krto)= @_;
  f_getreltypelist();
  _get_relates($key, 'key1', 'key2', \&_cb_gettorelates, $krto);
}

sub _cb_gettorelates  { my ($krto, $frelate)= @_;
  #print "_cb_gettorelates frelate=$frelate\n";
  my $desc= $frelate->{desc};  my $reltype= $f_reltypes{$desc};
  my $rtcat= $frelate->{rtcat};
  if (defined($rtcat))  {
    $frelate->{importance}+= 1  if $rtcat eq 'M';
  }
  my $rkey= $frelate->hashkey_trs(2, lc($frelate->{desc}. $frelate->{name2}));
  $krto->{$rkey}= $frelate;
}


sub get_fromrelates  { my ($key, $krfrom)= @_;
  f_getreltypelist();
  _get_relates($key, 'key2', 'key1', \&_cb_getfromrelates, $krfrom);
}

sub _cb_getfromrelates  { my ($krfrom, $frelate)= @_;
  #print "_cb_getfromrelates frelate=$frelate\n";
  my $rtcat= $frelate->{rtcat};
  if (defined($rtcat))  {
    $frelate->{importance}-= 1  if $rtcat eq 'M';
  }
  my $rkey= $frelate->hashkey_trs(2, lc($frelate->{name1}. $frelate->{desc}));
  #print "_cb_getfromrelates $krfrom=$krfrom rkey='$rkey'\n";
  $krfrom->{$rkey}= $frelate;
}


sub _get_relates  { my ($key, $nkey, $nkeyother, $callback, $cbarg)= @_;
  init();
  my $sth= $trelate->prepselect_binds("*", "$nkey=? and desc not null",  ($key));
  while (my $rec= dbtable::fetchselect($sth))  {
    my $frelate= frelate->new($rec);  $frelate->readnames();
    my $keyother= $frelate->{keyother}= $frelate->{$nkeyother};
    $frelate->{importance}= f::itemfieldfromkey($keyother, 'importance');
    $frelate->{maindoc}= f::itemfieldfromkey($keyother, 'maindoc');
    my $desc= $frelate->{desc};  $desc=~ s|\?||o;  my $reltype= $f_reltypes{$desc};
    if (defined($reltype))  {
      $frelate->{rtcat}= $reltype->{rtcat};
    }
    &$callback($cbarg, $frelate);
  }
  dbtable::finishselect($sth);
}

sub has_relates  { my ($key)= @_;
  init();
  my $sth= $trelate->prepselect_binds("key1",
                          "(key1=? or key2=?) and desc not null",
                          ($key, $key));
  my $rec= dbtable::fetchselect($sth);
  dbtable::finishselect($sth);
  return defined($rec);
}

sub relatedto { my ($key, $rikey)= @_;
  init();
  my $sth= $trelate->prepselect_binds("*",
                   "((key1=? and key2=?) or (key2=? and key1=?)) and desc not null",
                   ($key, $rikey, $key, $rikey));
  my $rec= dbtable::fetchselect($sth);
  dbtable::finishselect($sth);
  return 1  if defined($rec);
  return 0;
}


sub prune  {
  $trelate->exec_delete_null('desc');
}


1;

