package f;
#use Data::Dumper;
use Exporter;
use String::Util 'trim';
use mylib::db;
use myf::frelate; use myf::frdoc;  use myf::fattr;  use myf::fitem;  use myf::fsecentry;

@ISA=qw(Exporter);
@EXPORT=qw();


#---------------------------------------------------------------------------

our $ttp= undef;
our $inited= 0;
our $proxyspec;

sub init  {  my ($dbspec)= @_;
  return  if $inited;
  my $onwindows= $^O eq 'MSWin32';
  if (!defined($dbspec) or $dbspec eq '')  {
    if ($onwindows)  {
      $dbspec= 'sqlite.db';
    }  else  {
      $dbdir= $ENV{HOME}. '/personal';
      $dbdir= $ENV{HOME}  unless -d $dbdir;
      $dbspec= $dbdir. '/sqlite';
    }
    #print "f::init using'$dbspec'\n";
  }  else  {  print "f::init('$dbspec')\n";  }
  db::init($dbspec);
  fitem::init();
  fattr::init();
  frelate::init();
  frdoc::init();
  fsecentry::init();
    
  $ttp= dbtable->new('thoughtprompt', undef, 'id');
  $ttp->setfields('id','body');
  $ttp->create_table('id integer primary key, body text');
  prune();
 
  refresh();
  $inited= 1;
}

sub title  { return $db::file; }
sub deinit  { db::deinit(); }
sub refresh  { frelate::f_getreltypelist(); }


sub search  {  my ($listbyname, $pattern, $min, $max)= @_;
  return fitem::f_search($listbyname, $pattern, $min, $max);
}


sub itemnamefromkey {  my ($key)= @_;
  return fitem::f_itemfieldfromkey($key, 'name');
}

sub itemfieldfromkey {  my ($key, $field)= @_;
  return fitem::f_itemfieldfromkey($key, $field);
}

sub get_thoughtprompt {
  my @prompts= ();
  my $sth= $ttp->prepselect("*");
  while (my $rec= dbtable::fetchselect($sth))  {
    push(@prompts, $rec->{body});
  }
  dbtable::finishselect($sth);
  my $cnt= scalar(@prompts);
  return 'no thoughtprompts'  if $cnt==0;
  my $i= int(rand()*$cnt);
  #print "get_thoughprompt cnt=$cnt i=$i\n";
  return $prompts[$i];
}

#---------------------------------------------------------

sub prune  {
  prune_sections();
  frelate::prune();
  frdoc::prune();
  return fitem::f_enumerate_itemkeys(\&_cbpruneitem);
}

sub _cbpruneitem  {  my ($rec)= @_;
  #print $rec->{key}. ' ';
  #$llogtext.= '.';
  # don't prune if not empty...
  return 1 if $rec->{desc} ne '';
  return 1 if $rec->{nextactions} ne '';
  my $fitem= fitem->new($rec);
  return 1 if $fitem->has_secentries();
  return 1 if $fitem->has_relates();
  return 1 if $fitem->has_rdocs();
  $fitem->delentry();
}

sub prune_sections  {
  fsecentry::prune_sections();
}

1;
