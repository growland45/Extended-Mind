package frdoc;
use mylib::db;  use mylib::dbtable;  use mylib::files;  use mylib::htmlin;  use mylib::dbrec;
@ISA = ('dbrec');

our $trdoc= undef, $txdoc= undef, $tscansite= undef;
$impdflt= 1;
our @tscansite_fields= ('spec', 'base', 'tpattern', 'tantipattern', 'upattern', 'uantipattern');

sub init  {
  return if defined($trdoc);
  return unless defined($db::dbh);
  $trdoc= dbtable->new('rdoc', undef, 'key', 'spec');
  $trdoc->setfields('key', 'spec');
  $trdoc->create_table('key text not null, spec text,'.
                       ' PRIMARY KEY(key, spec)');
  my $count= $trdoc->count();  print "Total doc relates: $count\n";

  $txdoc= dbtable->new('externdoc', undef, 'spec', 'title');
  $txdoc->setfields('spec', 'title', 'titletries', 'importance', 'dynamic', 'peruse', 'altbrowse');
  $txdoc->create_table('spec text not null, title text, titletries integer, importance integer, '.
                       'dynamic integer, peruse integer, altbrowse integer, '.
                       ' PRIMARY KEY(spec)');
  $count= $txdoc->count();  print "Total external docs: $count\n";

  $tscansite= dbtable->new('scansite', undef, 'spec');
  $tscansite->setfields(@tscansite_fields);
  $tscansite->create_table('spec text not null, tpattern text, upattern text, uantipattern text, '.
                       ' PRIMARY KEY(spec)');
}

sub new { my ($class, $args) = @_;
  init();
  return $class->SUPER::new($args, $trdoc);
}

sub readfields  {  my ($self)= @_;
  my $rec= $self->SUPER::readfields();
  $self->{titletries}= rec::recdflt($self, 'titletries', 0)+ 0;

  $self->foldin($txdoc, 'spec');
  rec::filldflt($self, 'importance', $impdflt);
  rec::filldflt($self, 'dynamic', 0);
  rec::filldflt($self, 'peruse', 0);
  rec::filldflt($self, 'altbrowse', 0);

  my $rss= $self->foldin($tscansite, 'spec');
  $self->{isscansite}= defined($rss);
  return $rec;
}

sub title  { my ($self, $noproxy, $new)= @_;
  $new= 0  unless defined($new);
  my $spec= $self->{spec};
  $titletries= $self->{titletries};
  my $title= $self->{title};
  return $title if !$new  and defined($title)  and $title ne '';

  #print "frdoc::title spec='$spec' titletries=$titletries\n";
  $title= $self->{title}= files::titlefromspec($spec, $titletries, $noproxy);
  if (!defined($title) or ($title eq ''))  {
    #print "frdoc::title inc titletries\n";
    $self->{titletries}++;
    $self->save();
  }
  return $title;
}

sub btntitle { my ($self, $mwid)= @_;
  my $title= $self->{title};
  $title= $self->{spec}  unless defined($title) and $title ne '';
  $title= substr($title, 0, $mwid)  if defined($mwid);
  return $title;
}

sub save  { my ($self)= @_;
  my $spec= $self->{spec}= files::normalizefs($self->{spec});
  rec::filldflt($self, 'importance', $impdflt);
  rec::filldflt($self, 'dynamic', 0);
  rec::filldflt($self, 'peruse', 0);
  rec::filldflt($self, 'altbrowse', 0);
  print "frdoc::save spec=$spec, title='$self->{title}'\n";
  my $key= $self->{key};
  $trdoc->exec_insert("key, spec", "?,?", ($key, $spec)) if defined($key); # replace into
  $txdoc->exec_insert("spec, title, importance, titletries, dynamic, peruse, altbrowse", 
                      "?,?,?,?,?,?,?",
                      ($spec, $self->{title}, $self->{importance}, $self->{titletries},
                       $self->{dynamic}, $self->{peruse}, $self->{altbrowse})
                     ); # replace into
}


sub newentry  {  my ($self, $key, $spec)= @_;
  init();
  $self->{key}= $key;  $self->{spec}= files::normalizefs($spec);
  $self->{importance}= $impdflt;
  $self->{dynamic}= 0;
  $self->{peruse}= 0;
  $self->{altbrowse}= 0;
  $self->save();
}

sub delentry  { my ($self)= @_;
  $trdoc->exec_delete($self->{key}, $self->{spec});
}

sub hashkey  { my ($self, $typerank)= @_;  return $self->hashkey_trs(1, $self->sortkey());  }

sub sortkey  { my ($self)= @_;
  my $title= $self->{title};  $title= ''  unless defined($title);
  return $self->{spec}. $title. $self->{key}; 
}

#------------------------------------------------------------------------------

sub relatedto { my ($key, $spec)= @_;
  init();
  my $sth= $trdoc->prepselect_binds("*", "key=? and spec=?", ($key, $spec));
  my $rec= dbtable::fetchselect($sth);
  dbtable::finishselect($sth);
  return 1  if defined($rec);
  return 0;
}

sub get_rdocs { my ($key, $hash)= @_;
  #print "frdoc::getrdocs($key)...\n";
  init();
  my $sth= $trdoc->prepselect_binds("*", "key=? and spec not null", ($key));
  while (my $rec= dbtable::fetchselect($sth))  {
    my $frdoc= frdoc->new($rec);  $frdoc->readfields();
    $frdoc->hash_insert($hash);
  }
  dbtable::finishselect($sth);
}

sub get_byspec { my ($spec, $hash)= @_;
  #print "frdoc::getbyspec($spec)...\n";
  init();
  my $sth= $trdoc->prepselect_binds("*", "spec=?", ($spec));
  my $orphaned= 1;
  while (my $rec= dbtable::fetchselect($sth))  {
    #print "frdoc::getbyspec($spec)... $rec->{key}\n";
    my $frdoc= frdoc->new($rec);  $frdoc->readfields();
    $frdoc->hash_insert($hash);
    $orphaned= 0;
  }
  dbtable::finishselect($sth);
  $txdoc->exec_delete($spec)  if $orphaned;
}

sub has_rdocs { my ($key)= @_;
  init();
  my $sth= $trdoc->prepselect_binds("key", "key=? and spec not null", ($key));
  my $rec= dbtable::fetchselect($sth);
  dbtable::finishselect($sth);
  return defined($rec);
}

sub launch { my ($self)= @_;
  launchspec($self->{spec}, $self->{altbrowse});
}

#----------------------------------------------------------------------------------

sub launchspec { my ($spec)= @_;
  _logdoc($spec);
  my $tor= launchweb_torornot($spec);
  files::launch($spec, $tor);
}

sub launchweb_torornot { my ($spec)= @_;
  my $frdoc= frdoc->new({spec=>$spec});  $frdoc->readfields();
  return not $frdoc->{altbrowse};
}


sub delkeyspec { my ($key, $spec)= @_;
  init();
  $trdoc->exec_delete($key, $spec);
}

#-------------------------------------------------------------------------------------

sub fetchdoctitle  { my ($spec, $tryharder, $noproxy)= @_;
  #print "fetchdoctitle('$spec', $tryharder)\n";
  $tryharder= 0  unless defined($tryharder);
  my $rt= $txdoc->readrec("title", $spec);
  if (defined($rt) and $rt->{title} ne '')  {
    #print "  has title '$rt->{title}'\n";
    return $rt->{title};
  }

  my $title= files::titlefromspec($spec, $tryharder, $noproxy);
  #print "Derived doc title $spec -> $title\n";
  if (defined($title) and $title ne '')  {
    f_newdoctitle($spec, $title);
    return $title;
  }
  ($title)= $spec=~ m|/(.*?)$|o;
  #print "fetchdoctitle: $spec -> $title\n";
  $title= $spec  unless defined($title);
  return $title;
}


sub f_newdoctitle { my ($spec, $title)= @_;
  return  unless defined($title);
  #print "f_newdoctitle($spec, $title)\n";
  $txdoc->exec_insert("spec, title, importance, titletries, dynamic, peruse, altbrowse",
                      "?,?,?,?,?,?",
                      ($spec, $title, 1, 1, 0, 0, 0)); # replace into
}

sub makescansite { my ($self)= @_;
  return  if $self->{isscansite};
  f_newscansite($self->{spec});
  $self->{isscansite}= 1;
}

sub f_newscansite { my ($spec)= @_;
  return  unless defined($spec);
  $tscansite->exec_insert("spec, base, tpattern, tantipattern, upattern, uantipattern",
                          "?,'','','','',''",
                          ($spec)); # replace into
}


sub search_doctitle  {  my ($listbyspec, $pattern, $min, $max)= @_;
  $min= 15  unless defined($min);
  $max= 100  unless defined($max);
  my $cnt= 0;
  $spattern= '%'. $pattern. '%';
  my $sth= $txdoc->prepselect_binds("*",
          "title like ? or spec like ? order by -importance, title", ($spattern, $spattern));
  while (my $rec= dbtable::fetchselect($sth))  {
    my $title= $rec->{title};  my $spec= $rec->{spec};
    $title= $spec  unless defined($title) and $title ne '';
    #print "search_doctitle: '$spec' '$title'\n";
    $listbyspec->{$title}= frdoc->new($rec);
    $cnt++;    last  if $cnt>= $max;
  }
  dbtable::finishselect($sth);
  return  if $cnt>= $min;

  #$cnt+= _search_files('webdl', $listbyspec, $pattern, $min-$cnt, $max-$cnt);  
  #return  if $cnt>= $min;
  #$cnt+= _search_files('bt.*', $listbyspec, $pattern, $min-$cnt, $max-$cnt);  
}

sub _search_files  {  my ($dir, $listbyspec, $pattern, $min, $max)= @_;
  my $cnt= 0;
  my $home= $ENV{'HOME'};
  open FP, "find $home/$dir |" or return;
  while ($cnt< $min)  {
    my $fs= <FP> or last;
    chomp($fs);  $fs= files::normalizefs($fs);
    next if $fs=~ m|/bak$|o;
    next if $fs=~ m|/bak/|o;
    next if $fs=~ m|_files$|o;
    next if $fs=~ m|\~$|o;
    next unless $fs=~ m|$pattern|o;
    my $title= fetchdoctitle($fs);
    my %rec;  $rec{title}= $title;  $rec{importance}= 0;
    $listbyspec->{$fs}= frdoc->new(\%rec);
    $cnt++;
  }
  close(FP);
  return $cnt;
}

sub search_dynamics  {  my ($listbyspec, $max)= @_;
  _search_flag($listbyspec, 'dynamic', $max);
}

sub search_peruses  {  my ($listbyspec, $max)= @_;
  _search_flag($listbyspec, 'peruse', $max);
}


sub _search_flag  {  my ($listbyspec, $field, $max)= @_;
  $max= 100  unless defined($max);
  my $cnt= 0;
  my $sth= $txdoc->prepselect("*",
          "where $field=1 order by -importance, title");
  while (my $rec= dbtable::fetchselect($sth))  {
    my $frdoc= frdoc->new($rec);
    my $title= $frdoc->btntitle();
    #print "search_dynamics: '$spec' '$title'\n";
    my $skey= (9-$frdoc->{importance}). $title;
    $listbyspec->{$skey}= $frdoc;
    $cnt++;    last  if $cnt>= $max;
  }
  dbtable::finishselect($sth);
}

#-------------------------------------------------------------------
sub get_scansites { my ($hash)= @_;
  init();
  my $sth= $tscansite->prepselect("*");
  while (my $rec= dbtable::fetchselect($sth))  {
    my $fsite= frdoc->new($rec);
    $fsite->readfields();
    $fsite->hash_insert($hash);
  }
  dbtable::finishselect($sth);
}

sub parse { my ($s, $hrefs, $rtitle, $proxy)= @_;
  $s->{hrefs}= $hrefs;
  my $hi= htmlin->new();
  $hi->set_ahref_callback(\&_ahrefcb, $s);
  my $spec= $s->{spec};
  #print "fscansite::parse site=$site\n";
  return 0  unless $hi->parse_geturl($spec, $proxy);
  $$rtitle= $hi->{title};
  return 1;
}

sub _ahrefcb { my ($s, $url, $title)= @_;
  #print "fscansite::ahrefcb url='$url' title='$title'\n"; $DB::single=1;
  return  unless _match($title, $s->{tpattern});
  return  unless _freeof($title, $s->{tantipattern});
  return  unless _match($url, $s->{upattern});
  return  unless _freeof($url, $s->{uantipattern});
  my $hrefs= $s->{hrefs};
  $hrefs->{$url}= $title;
  #print "$title\n";
}

sub _match { my ($string, $pstr)= @_;
  return 1  unless defined($pstr);  return 1  if $pstr eq '';
  #print _match '$string' '$pattern'\n";
  my @patterns= split(/\s/, $pstr);
  foreach my $pattern (@patterns)  {  return 1 if $string=~ m|$pattern|i;  }
  return 0;
}

sub _freeof { my ($string, $pstr)= @_;
  return 1  unless defined($pstr);  return 1  if $pstr eq '';
  #print _freeof '$string' '$pattern'\n";
  my @patterns= split(/\s/, $pstr);
  foreach my $pattern (@patterns)  {  return 0 if $string=~ m|$pattern|i;  }
  return 1;
}

sub canonical_url { my ($self, $url)= @_;
  my $sitespec= $self->{spec};
  if ($url=~ m|^\/\/|o)  { # seen on Slashdot
    #print "MUNGING '$url' ";
    $url= 'http://'. $url;
    #print "TO '$url' \n";
    return $url;
  }
  if ($url=~ m|^\/|o)  {
    my $slashbase= $self->{slashbase};
    #print "MUNGING '$url' ";
    $url=~s|^\/||o;
    $url= $slashbase. $url;
    #print "TO '$url' \n";
    return $url;
  }
  unless ($url=~ m|http|io) {
    my $base= $self->{base};
    #print "MUNGING '$url' ";
    $url=~s|^\/||o;
    $url= $base. $url;
    #print "TO '$url' \n";
    return $url;
  }
  #print "KEEPING $url\n";
  return $url;
}


#-------------------------------------------------------------------

%recentdocs= ();
$rimax=10;

sub _logdoc  {  my ($spec)= @_;
  return  unless defined($spec);
  #print "logitem '$spec'\n";
  return  if $spec eq '';
  $recentdocs{$spec}= time();
  recentdocs_trim($rimax);
}

sub recentdocs_trim { my ($maxcnt)= @_;
  my @s= sort { $recentdocs{$b} <=> $recentdocs{$a} } keys %recentdocs;
  my $cnt= 0;
  foreach my $key (@s)  {
    if ($cnt> $maxcnt)  {  delete $recentdocs{$key};  }
    $cnt++;
  }
}

sub isrecent { my ($spec)=@_;
  my $rec= $recentdocs{$spec};
  return defined($rec);
}

sub chooserandomdoc {  my ($list)= @_;
  my @dkeys= ();
  foreach my $dkey (keys %$list)  {   push(@dkeys, $list->{$dkey});  }
  my $cnt= scalar(@dkeys);
  return undef  if $cnt==0;
  my $tries= 5;  my $rec;
  while ($tries> 0)  {
    my $i= int(rand()*$cnt);
    $rec= $dkeys[$i];
    return $rec unless isrecent($rec->{spec});
    $tries--;
  }
  return $rec; # settle
}

sub prune  {
  $trdoc->exec_delete_null('spec');
}

1;
