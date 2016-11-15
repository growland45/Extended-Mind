package mypitem;
use Tk;  use Module::Load;
use myf::fitem;  use myf::fsecentry;  use myf::frdoc;
use mylib::db;  use mytk::g;  use mytk::tabpane;
@ISA = ('tabpane');

#-----------------------------------------------------------------

our $tabrow= undef;

sub btext { my ($self)=@_;
  my $fitem= $self->{fitem};
  if (defined($fitem))  {
    return $fitem->{name}  if defined $fitem->{name};
  }
  return "Item";
}

$inited= 0;
sub init  {
  return  if $inited;
  push @INC, './mypi';
  $inited= 1;
}

sub launch  {  my ($self, $key, $secid)= @_;
  #print "mypitem::launch(self=$self key=$key secid=$secid)\n";
  init();
  $self->{srec}= undef;  $self->{secid}= $secid;
  if (!defined($key))  {
    if (!defined($secid))  { print "WARN mypitem bad launch args\n"; return; }
    my $srec= fsecentry::fetch_byid($secid);
    if (!defined($srec))  { print "WARN mypitem bad secid=$secid\n"; return; }
    $self->{srec}= $srec;
    $key= $srec->{ikey};
  }
  if (!defined($key))  { print "WARN mypitem bad launch args key=$key secid=$secid\n"; return; }
  #print "mypitem::launch key='$key'\n";
  my $args= {key=>$key};  $self->setitem($args);
  $self->{secid}= $secid;
}

sub saveonleave { my ($self) = @_;
  $tabrow= undef;  $self->{srec}= undef;
}

sub setitem { my ($self, $args)= @_;
  $self->destroy(); # in case re-use.
  $fitem= $self->{fitem}= fitem->new($args);
  return  unless $fitem->readfields();
  logitem($fitem->{key});
  #print $self->{fitem}->{cat}. "\n";
}

sub populate {  my ($self)= @_;
  my $w= $self->{window};
  my $fitem= $self->{fitem};
  $fitem->readfields();
  $fitem->have_a_maindoc();

  $tscratch= '';
  my $cr= $w->{cr}= g::ctlrow($w);
  #my $keyshow= g::entry($cr, 8, $self->{key});  g::entry_set($keyshow, $fitem->{key});
  $self->{name}= $self->{cat}= '';
  #g::varlabel($cr, \$self->{name}, 24);
  $self->{name}= $fitem->{name};
  my $cat= $fitem->{cat};  $self->{cat}= $cat  if defined($cat);

  $tabrow= $w->{tabrow}= 
       tabrow->new({parent=>$cr, labelvar=>\$tscratch, mainpanel=>$w},
                    {fitem=>$fitem});

  my $gotsrec= defined($self->{srec});
  #print "mypitem::populate gotsrec=$gotsrec\n";
  $tabrow->classtab('pimain', {pitem=>$self}, !$gotsrec, 1);
  $tabrow->classtab('pisections', {pitem=>$self});
  $tabrow->classtab('pisections_action', {pitem=>$self});
  $tabrow->classtab('pinewrelate', {pitem=>$self});
  $tabrow->classtab('pinewattr', {pitem=>$self});
  $tabrow->classtab('pinewrdoc', {pitem=>$self});

  g::label($cr, f::get_thoughtprompt(), 5);
  g::timer_reset();

  # decide whether to launch section...
  my $srec= $self->{srec};
  return unless defined($srec);

  my $isaction= $srec->isactiontype();
  my $pclass= 'pisections';  $pclass= 'pisections_action'  if $isaction;
  my $tabrow= $self->{window}->{tabrow};
  $tabrow->launchsw($pclass, $srec->{id});  #$self->switchto();
}


sub pop_not  { my ($self, $not, $grid, $isaction)= @_; # used by many panes in mypi
  $isaction= 0  unless defined($isaction);
  my $maxfsz= $grid->{maxfsz};
  my $fsz= $grid->{mfsz}+ $not->rank();  $fsz= $maxfsz  if $fsz> $maxfsz;
  my $bwid= $grid->{bwid};  $bwid-= $fsz*2;
  my $title= substr($not->{title}, 0, $bwid);
  g::menu_button($grid, $title, [\&_gswitchto_noteorthought, $self, $not, $isaction], $fsz, $activate);
}

sub _gswitchto_noteorthought { my ($self, $not, $isaction)= @_;
  $isaction= 0  unless defined($isaction);
  my $w= $self->{window};  my $tr= $w->{tabrow};
  my $pc= 'pisections';  $pc= 'pisections_action'  if $isaction;
  $tr->launchsw($pc, $not->{id});
}


#------------------------------------------------------------------------------------------


sub gpopmaindoc  { my ($maindoc, $g, $dwid, $fsz)= @_;
  # displays deep link into item given maindoc value
  if ($maindoc=~ m|^S (.*)$|iog)  {
    #print "maindoc='$maindoc' id='$1'\n";
    my $fse= fsecentry::fetch_byid($1);
    _pop_section($fse, $g);
    return;
  }
  my $mdoctitle= frdoc::fetchdoctitle($maindoc, 0);
  $mdoctitle= "Main doc"  unless defined($mdoctitle);
  g::menu_button($g, '('. substr($mdoctitle, 0, $dwid-2). ')', 
                 [\&frdoc::launchspec, $maindoc], $fsz);
}

sub _pop_section  { my ($fse, $g)=@_;
  my $btext= substr($fse->{title}, 0, 35);
  my $id= $fse->{id};  #print "mrelates::_pop_section: '$id'\n";
  main::glaunchsecbtn($g, $btext, $id);
}

sub gdoswcmd  { my ($class, $key1, $key2, $key3)= @_;
  g::timer_reset();
  return tabrow::launchsw($tabrow, $class, $fitem->{key}, $key1, $key2);
}


#-------------------------------------------------------------

%recentitems= ();
$latestitem= undef;
$rimax= 11;

sub recentitems  {
  return \%recentitems;
}

sub isrecent  { my ($key)= @_;
  my $rec= $recentitems{$key};
  return defined($rec);
}

sub logitem  {  my ($key)= @_;
  return  unless defined($key);
  #print "logitem '$key'\n";
  return  if $key eq '';
  $latestitem= $key;
  $recentitems{$key}= time();
  _recentitems_trim($rimax);
}

sub _recentitems_trim { my ($maxcnt)= @_;
  my @s= sort { $recentitems{$b} <=> $recentitems{$a} } keys %recentitems;
  my $cnt= 0;
  foreach my $key (@s)  {
    if ($cnt> $maxcnt)  {  delete $recentitems{$key};  }
    $cnt++;
  }
}

sub chooserandom  {
  my $key;  my $tries= 5;
  while ($tries> 0)  {
    $key= fitem::chooserandom();
    return $key  unless isrecent($key);
    $tries--;
  }
  return $key;  # settle
}

1;

