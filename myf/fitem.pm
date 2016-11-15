package fitem;
use mylib::db;  use mylib::dbrec;
use myf::frdoc;  use myf::f;  use myf::fsecentry;  use myf::fattr;
@ISA = ('dbrec');

$debug= 0;
our $ti= undef;

sub init  {
  return  if defined($ti);
  $ti= dbtable->new('item', undef, 'key');
  $ti->setfields('key', 'name', 'desc', 'ponderfocus', 'importance', 'maindoc');
  $ti->create_table('key text primary key, name text not null, '.
                    'desc text, ponderfocus integer, '.
                    'importance integer, maindoc text');
  $ti->create_index('importance');
  my $count= $ti->count();  print "Total items: $count\n";
}

sub new { my ($class, $args) = @_;
  init();
  return $class->SUPER::new($args, $ti);
}


sub fitem_from_key { my ($key)= @_;
  init();
  my $rec= $ti->readrec("key, name, importance", $key);
  return  undef  unless defined($rec);
  return fitem->new($rec); 
}

sub readfields  {  my ($self, $key)= @_;
  init();
  $self->{key}= $key  if defined($key);
  #print "fitem::readfields: '$key'\n";
  my $rec= $self->SUPER::readfields();
  $DB::single=1  unless defined($rec->{name});
  return 0  unless defined($rec);

  #rec::filldflt($self, 'actfocus', 0);
  rec::filldflt($self, 'ponderfocus', 0);
  rec::filldflt($self, 'importance', 1);
  return 1;
}


sub choose_maindoc { my ($self)= @_;
  my %dangles;
  $self->{maindoc}= ''; # in case none
  $self->get_rdocs(\%dangles);
  $self->get_sectionlist('notes', \%dangles);
  foreach my $rkey (sort keys %dangles)  {
    my $dangle= $dangles{$rkey};  my $ref= ref $dangle;
    next  unless 0+ $dangle->{importance}> 1;
    if ($ref eq 'frdoc')  { $self->{maindoc}= $dangle->{spec};  }
    else  {  $self->{maindoc}= "S ". $dangle->{id};  }
    last;
  }
  $self->save();
}

sub have_a_maindoc { my ($self)= @_;
  $self->choose_maindoc()  if  !defined($self->{maindoc}) or $self->{maindoc} eq '';
}

sub save  { my ($self)= @_;
  init();
  $ti->exec_set("desc=?, actfocus=?, ponderfocus=?, importance=?, maindoc=?",
        ($self->{desc},
         $self->{actfocus}, $self->{ponderfocus},
         $self->{importance}, rec::recdflt($self, 'maindoc', ''),
         $self->{key}));
}

sub newentry  {  my ($self, $name)= @_;
  init();
  rec::filldflt($self, 'importance', 1);
  rec::filldflt($self, 'actfocus', 0);
  rec::filldflt($self, 'ponderfocus', 0);
  my $importance= $self->{importance};
  $self->{name}= $name;
  $self->{key}= my $key= db::abbrev($name);
  #return undef unless
  $ti->exec_new("desc, key, name, importance, actfocus, ponderfocus",
                             "'', ?,?,?, 0, 0", ($key, $name, $importance));
  return $key;
}

sub delentry { my ($self)= @_;
  init();
  $ti->exec_delete($self->{key});
}

#----------------------------------------------------------------------


sub sectionexists {  my ($self, $section)= @_;
  my $key= $self->{key};
  return fsecentry::f_sectionexists($key, $section);
}

sub get_sectionlist { my ($self, $type, $hash)= @_;
  return fsecentry::f_getsectionlist($self->{key}, $type, $hash);
}

sub has_secentries { my ($self)= @_;
  return fsecentry::f_hassecentries($self->{key});
}

sub new_secentry { my ($self, $type)= @_;
  return fsecentry::f_newsecentry($self->{key}, $type);
}




#----------------------------------------------------------------------

sub has_relates { my ($self)= @_;
  return frelate::has_relates($self->{key});
}

sub relatedto { my ($self, $rikey)= @_;
  return frelate::relatedto($self->{key}, $rikey);
}

sub get_attrs  { my ($self, $hash)= @_;
  return fattr::get_attrs($self->{key}, $hash);
}

sub get_rdocs  { my ($self, $hash)= @_;
  return frdoc::get_rdocs($self->{key}, $hash);
}

sub has_rdocs { my ($self)= @_;
  return frdoc::has_rdocs($self->{key});
}

#----------------------------------------------------------------------

sub f_itemfieldfromkey {  my ($key, $field)= @_;
  my $rec= $ti->readrec($field, $key);
  return $rec->{$field};
}


sub f_textfromkey { my ($key, $l)= @_;
  $l= 50 unless defined($l);
  my $fitem= fitem->new({key=>$key});  return undef  unless defined($fitem);
  return undef  unless $fitem->readfields();

  my $name= $fitem->{name};
  $DB::single=1  unless defined($name);
  return undef  unless defined($name);  return undef if $name eq '';
  my $btext= $name; $btext= substr($btext, 0, $l);
  return $btext;
}

sub f_enumerate_itemkeys  {  my ($callback, $passarg)= @_;
  init();
  my $sth= $ti->prepselect("*", 'order by importance desc, name');
  while (my $rec= dbtable::fetchselect($sth))  {
    my $fitem= fitem->new($rec);
    last  unless &$callback($fitem, $passarg);
  }
  dbtable::finishselect($sth);
}

sub f_enumerate_itemkeys_flag  {  my ($callback, $flag, $passarg)= @_;
  init();
  my $sth= $ti->prepselect_binds("name,key,importance", "$flag=1 order by importance desc, name");
  while (my $rec= dbtable::fetchselect($sth))  {
    my $fitem= fitem->new($rec);
    last  unless &$callback($fitem, $passarg);
  }
  dbtable::finishselect($sth);
}


sub f_search  {  my ($listbyname, $pattern, $min, $max)= @_;
  $min= 15  unless defined($min);
  $max= 100  unless defined($max);
  $cnt= _search($listbyname, $pattern, $min, $max); # always find exact match if exists
  $cnt+= _search($listbyname, $pattern. '%', $min- $cnt, $max- $cnt);
  _search($listbyname, '%'. $pattern. '%', $min- $cnt, $max- $cnt);
}

sub _search  {  my ($listbyname, $pattern, $min, $max)= @_;
  my $cnt= 0;
  my $sth= $ti->prepselect_binds("name, key, importance",
          "name like ? or desc like ? ".
          "order by importance desc, name COLLATE NOCASE",
          ($pattern, $pattern));
  while (my $rec= dbtable::fetchselect($sth))  {
    my $name= $rec->{name};  my $key= $rec->{key};  my $direction= $rec->{direction};
    #print "search: '$name' '$key'\n";
    my @aitem= ($rec->{name}, $rec->{key}, $rec->{importance});
    my $skey= sprintf("%i", 9- $rec->{importance}). $name;
    $listbyname->{$skey}= \@aitem;
    $cnt++;
    last  if $cnt>= $max;
  }
  dbtable::finishselect($sth);
  return $cnt;
}


sub chooserandom  {
  my @ikeys= ();
  my $sth= $ti->prepselect('key');
  while (my $rec= dbtable::fetchselect($sth))  {
    my $i= $rec->{importance};
    while ($i>= 0)  {  push(@ikeys, $rec->{key});  $i--; }
  }
  dbtable::finishselect($sth);
  my $cnt= scalar(@ikeys);
  return undef  if $cnt==0;
  my $i= int(rand()*$cnt);
  return $ikeys[$i];
}

1;
