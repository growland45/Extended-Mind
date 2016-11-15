package tp; # text edit panes
use mytk::g;  use mytk::gcore;
use Tk;
use utf8;  use English;
$onwindows= $^O eq 'MSWin32';
if (!$onwindows)  {  # won't compile there.
  require Text::Aspell;
}


sub tpmake  {  my ($parent, $bufref, $height, $width, $fsz)=@_;
  $width= 67  unless defined($width);
  $fsz= -1  unless defined($fsz);
  my $font= gcore::choosefont($fsz); # fixed font
  my $tw= $parent-> Scrolled('Text', -scrollbars=>'oe',
		    -wrap=> "word", # -spacing1=>3,
		    -width=> $width, -height=> $height,
		    -font=> $font, -padx=> 3,
		    -bg=> $gcore::clr{bg}, -fg=> $gcore::clr{fg},
		    -insertbackground=> 'yellow');
  $DB::single = 1  unless defined($tw);
  gcore::mypack($tw, $parent);
  if (defined($bufref))  {  tpload($tw, $bufref);  }
  return $tw;
}

sub tpclear { my ($tw)= @_;
  $tw->delete('1.0', 'end');
}

sub tpadd  {  my ($tw, $newtext)= @_;
  $tw->insert('end', $newtext);
  $tw->see('end');
}

sub tpload  {  my ($tw, $bufref)= @_;
  $DB::single = 1  unless defined($tw);
  my $oldbufref= $tw->{bufref};
  #print "tpload($tw,$bufref) oldbufref=$oldbufref\n";
  if (defined($bufref))  { $tw->{bufref}= $bufref; } 
  else  { $bufref= $oldbufref; }
  #print "tpload: $tw\nbufref=$bufref\n[$$bufref]\n";
  $tw->delete('1.0', 'end');
  $tw->insert('1.0', $$bufref);
}

sub tpunload  { my ($tw, $niceify)= @_;  # returns flag whether changed
  $DB::single = 1  unless defined($tw);
  $niceify= 0  unless defined($niceify);
  my $bufref= $tw->{bufref};
  my $old= $$bufref;
  $$bufref= $tw-> get('0.0', 'end');
  $$bufref=~ s|[\r\n]*$||s;
  text_niceify($bufref)  if $niceify;
  return $$bufref ne $old;
}

sub tpniceify  { my ($tw)= @_;
  tpunload($tw, 1);
  tpload($tw);
}

sub tpspellcheck  { my ($tw, $callback, $carg0)= @_;
  return  if $onwindows;
  # http://search.cpan.org/~hank/Text-Aspell/Aspell.pm
  my $speller = Text::Aspell->new;  die unless $speller;
  $speller->set_option('lang','en_US');  $speller->set_option('sug-mode','fast');
  tpunload($tw);
  my $bufref= $tw->{bufref};
  my @words= split(/\b/, $$bufref);
  foreach my $word (@words)  {
    next  if $word=~ m|\W|g;
    next  if $speller->check($word);
    my @suggestions = $speller->suggest( $misspelled );
    if (defined($carg0))  { &$callback($carg0, $word, @suggestions); }
    else  { &$callback($word, @suggestions); }
  }
}

sub word_count { my ($tw)= @_;
  tpunload($tw);
  my $bufref= $tw->{bufref};
  my @words= split(/\s+/, $$bufref);
  return  scalar(@words);
}

sub text_niceify { my ($bufref)= @_; # for human-destined text, not code.
  #$DB::single=1;
  $$bufref= ucfirst($$bufref);
  $$bufref=~ s|\.(\s+)([a-z])|.$1\U$2|omg;  # capitalize each sentence.
# http://coderzone.org/library/Capitalize-The-First-Word-In-A-Sentence_1001.htm
# ucfirst
  #$$bufref=~ s|(\w)\'(\w)|$1’$2|iog;
  #$$bufref=~ s|"|”|iog  #$$bufref=~ s|"(\s)|”$1|iog
  #$$bufref=~ s|(\w)\'(\w)|TEST|iog;
}


1;

