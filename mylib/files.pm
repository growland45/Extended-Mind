package files;
use mylib::net;  use mylib::config;
use Encode qw(encode decode); use URI;
use utf8;

our $onwindows= int($^O eq 'MSWin32');
#require Win32::FileOp qw(ShellExecute)  if $onwindows;



sub launch { my ($spec, $tor)= @_;
  #print "files::launch($spec, $tor)\n";
  if ($spec=~ m|^https*\:\/\/|o)  {
    launchweb($spec, $tor);
  }  elsif  ($spec=~ m|\.txt$|io)  {
    $spec= expandfs($spec);
    my $editor= config::V('editor');
    $cmd= "$editor $spec";
    spawn($cmd);
  }  else  {
    $spec= expandfs($spec);
    my $startcmd= config::V('startcmd');
    my $cmd= "$startcmd '$spec'";  $cmd= $spec  if $onwindows;
    #print "files::launch $cmd\n";
    return if 0== spawn($cmd);
    }
}

sub spawn { my ($cmd)= @_;
  if ($onwindows)  {
    print "files::spawn cmd='$cmd'\n";
    if ($onwindows and $cmd=~ m|\.exe|io)  { return system($cmd); }
    return system("start $cmd");
  }
  return system("$cmd &");
}

sub launchweb { my ($spec, $tor)= @_;
  $tor= 1  unless defined($tor);
  my $cmd;
  if (!$onwindows)  {
    my $torbrowser= config::V('browser');
    my $nontorbrowser= config::V('altbrowser');
    $cmd= "$torbrowser '$spec'";
    $cmd= "$nontorbrowser '$spec'"  unless $tor;
  }  else  {
    $cmd= "$spec";
  }
  #print "files::launch  $cmd\n";
  spawn($cmd);
}


sub playsound { my ($path)= @_;
  $path= expandfs($path);
  return  unless -e $path;
  system("play $path");
}


sub normalizefs { my ($fs)= @_;
  return  $fs if $onwindows; # not supported
  my $home= $ENV{'HOME'};
  $fs=~ s|^$home|~|;
  return $fs;
}

sub expandfs { my ($fs)= @_;
  return  $fs  if $onwindows;
  my $home= $ENV{'HOME'};
  $fs=~ s|^\~|$home|;
  return $fs;
}

sub titlefromhtml { my ($html)= @_;
  return  undef  if !defined($html);
  $html= decode("utf8", $html);
  my $title= undef;
  #print "HTML:\n";  print $html;  print "\n...HTML\n";
  #print "titlefromhtml: ". substr($1, 0, 100). "\n"  if $html=~ m|<(.*)|ios;
  if ($html=~ m|<title.*?>(.*?)<|ios)  {
    $title= html_decrappify($1);
    $title =~ s|^the ||io;
    $title=~ s|^.*?ebook of ||io;
    $title=~ s|\&.*?;| |iog; # not worth the bother
    $s =~ tr/\r\n/ /d;
    print "titlefromhtml: '$title'\n";
  }  
  return $title;
}

sub html_decrappify { my ($s)= @_;
  $s=~ s|^\s+||o;# leading whitespace
  $s=~ s|\s+$||o;# trailing whitespace
  $s=~ s|[\x80]||og;
  $s=~ s|[\x93\x94]|-|iog;
  $s=~ s|[\x98\x99]|'|iog;
  $s=~ s|[\x9c\x9d]|'|iog;
  $s=~ s|\n| |omg;  $s=~ s|\&laquo\;||io;
  $s=~ s|\&#039;|'|iog;  $s=~ s|\&#39;|'|iog;
  $s=~ s|\&#34;|"|iog;
  $s=~ s|\&#45;|-|iog;
  $s=~ s|\&#8211\;|-|iog;
  $s=~ s|\&#8216\;|'|iog;  $s=~ s|\&#8217\;|'|iog;
  $s=~ s|\&#8220\;|“|iog;  $s=~ s|\&#8221\;|”|iog;
  # http://rabbit.eng.miami.edu/info/htmlchars.html
  $s=~ s|\&amp;|\&|iog;
  $s=~ s|\&lt;|\<|iog;
  $s=~ s|\&gt;|\>|iog;
  $s=~ s|\Qâ\E| |og;
  $s=~ s|\QÂ\E| |og;
  $s=~ s|\&quot;|\"|iog;
  return $s;
}


sub slashbasefromurl { my ($url)= @_;
  # http://stackoverflow.com/questions/11402706/getting-the-base-url-of-a-url
  my $buri= URI->new_abs("/", $url);
  return "$buri"; 
}

sub dotbasefromurl { my ($url)= @_;
  # http://stackoverflow.com/questions/11402706/getting-the-base-url-of-a-url
  my $buri= URI->new_abs(".", $url);
  return "$buri"; 
}


sub titlefromhtmlfile { my ($fs)= @_;
  $fs= expandfs($fs);
  #print "files::titlefromhtmlfile '$fs'\n";
  open(FI, '<', $fs);    read(FI, my $glob, 990000);    close(FI);
  my $htitle= titlefromhtml($glob);
  return $htitle;
}

sub titlefromfile { my ($fs)= @_;
  $fs= expandfs($fs);
  #print "files::titlefromfile($fs)\n";
  if (-d $fs)  { return $fs; }
  if ($fs=~ m|\.htm|io)  {  return titlefromhtmlfile($fs);  }
  return $undef;
}

sub titlefromurl { my ($url, $tryharder, $noproxy)= @_;
  #print "files::titlefromurl('$url', $tryharder)\n";
  $noproxy= 0  unless defined($noproxy);
  $timeout= 10;
  $url=~ s|^https|http|io;  
  my $html= net::httpget($url, $timeout, !$noproxy);
  if (!defined($html) and $tryharder)  {
    $html= net::httpget($url, $timeout*(2+$tryharder), !$noproxy);
  }
  if (!defined($html) and $noproxy or $tryharder>4)  {
    print "titlefromurl '$url': trying no proxy\n";
    $html= net::httpget($url, $timeout*(2+$tryharder), 0);
  }
  if (!defined($html) and $tryharder> 6)  {
    print "titlefromurl '$url': giving up\n";
    $url=~ s|^http.*//||o;
    return $url;
  }

  if (!defined($html))  {
    print "titlefromurl '$url': NO HTML\n";
    return undef;
  }

  #my $h1= substr($html, 0, 100); print "httpget returned '$h1'\n";
  my $title= titlefromhtml($html);
  if (!defined($title))  {
    print "titlefromurl('$url'): HTML but can't get title\n";
    print "\n\nHTML is [[". substr($html, 0, 500). "]]\n";;
    $url=~ s|^http.*//||o;
    return ("NT $url");
  }
  #print "titlefromurl('$url'): '$title'\n";
  return $title;
}

sub titlefromspec { my ($spec, $tryharder, $noproxy)= @_;
  #print "files::titlefromspec('$spec', $tryharder)\n";
  if ($spec=~ m|^http.*\:\/\/|o)  {  return titlefromurl($spec, $tryharder, $noproxy); }
  return titlefromfile($spec);
}

1;
