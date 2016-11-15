package net;
use LWP::UserAgent;
use LWP::Protocol::https;
use Net::FTP;
use mylib::config;
use open ':utf8';
use utf8;

sub httpget { my ($url, $timeout, $proxy)= @_;
  my ($content, $base)= httpget_base($url, $timeout, $proxy);
  return $content;
}

sub httpget_base { my ($url, $timeout, $proxy)= @_;
  $proxy= 1  unless defined($proxy);
  $url=~ s|^https|http|o;
  $ua = LWP::UserAgent->new;
  $ua->agent(config::V('uastring'));
  $ua->timeout($timeout)  if defined($timeout);
  print "GET $url ...\n";
  my $httpproxy= config::V('httpproxy');
  if ($proxy and defined($httpproxy))  {
    $ua->proxy(['http'], $httpproxy);
    print "  PROXY: $httpproxy\n";
  }
  my $req = HTTP::Request->new(GET => $url);
  my $res = $ua->request($req);

  my $content= $res->content;
  if ($res->is_success and defined($content) and $content ne '') { return ($content, $res->base); }

  my $statusline= $res->status_line;
  print "NO HTML proxy='$proxy' status='$statusline' URL: $url\n";
  return undef;
}

#---------------------------------------------------------------

sub ftp_mget { my ($host, $acct, $dir, $ldir, $pass)= @_;
  my $dbg= 0;
  my $olddir= `cwd`;
  #$dir= $ENV{'HOME'}. '/actorlogs';
  #mkdir($dir, 0777);  chdir($dir)  or die "Can't chdir $dir\n";
  my $ftp= Net::FTP->new($host, Debug=>$dbg, Passive=>1)  or die "Can't connect: $@\n";
  $ftp->login($acct, $pass)  or die "Can't login\n";
  $ftp->binary();
  ftp_mget_dodir($ftp, $dir, $ldir);
  $ftp->quit();
  chdir($olddir);
}

sub ftp_mget_dodir  { my ($ftp, $dir, $ldir)= @_;
  return  if $dir eq '.';  return  if $dir eq '..';
  unless (-d $ldir)  {
    unless (mkdir($ldir))  {
      print "Can't mkdir $ldir\n";
      return;
    }
  }
  chdir ($ldir) or return;

  if (defined($dir))  {
    unless ($ftp->cwd($dir))  {
      print "Can't cwd $dir\n";
      return;
    }
  }  else  {
    $dir= $ftp->pwd();  $dir=~s|\/$||og;
  }
  #$ftp->get('index.html');
  my @cantget= ();
  my @entries= $ftp->ls();
  foreach $entry (@entries)  {
    next if $entry eq '.';
    next if $entry eq '..';
    my $rdtm= $ftp->mdtm($entry);
    if (!$ftp->get($entry)) { push @cantget, $entry;  next; }
    print "Fetched $entry\n";
    utime($rdtm, $rdtm, $entry);
  }
  foreach $entry (@cantget)  {
    print "Can't get $entry: $@\n";
    my $dirsub= "$dir/$entry";
    my $ldirsub= "$ldir/$entry";
    #print "Would fetch $dirsub to $ldirsub\n";
    ftp_mget_dodir($ftp, $dirsub, $ldirsub); # recurse
  }
}

1;

