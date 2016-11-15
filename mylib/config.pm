package config;
use utf8;

our $onwindows= int($^O eq 'MSWin32');
our %S;
# This makes a difference:  http://whatsmyuseragent.com/
$S{uastring}=   'Mozilla/5.0 (X11; Linux i686; rv:24.0) Gecko/20140429 Firefox/24.0 Iceweasel/24.5.0';
$S{httpproxy}=  'http://127.0.0.1:8118/'; $S{httpproxy}=''       if $onwindows;
$S{browser}=    'iceweasel';
$S{altbrowser}= 'konqueror';
$S{startcmd}=   'pcmanfm';                $S{startcmd}= ''       if $onwindows;
$S{editor}=     'gedit';                  $S{editor}= 'notepad'  if $onwindows;

sub V  { my ($key)= @_;  return $S{$key}; }

1;

