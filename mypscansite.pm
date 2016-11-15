package mypscansite;
use Tk;
use myf::f;  use myf::frdoc;
use mytk::g;  use mylib::files; use mytk::tabpane;
@ISA = ('tabpane');

#-----------------------------------------------------------------


sub btext { my ($self)=@_;
  my $fsite= $self->{fsite};
  if (defined($fsite))  {
    return $fsite->{title}  if defined $fsite->{title};
  }
  return "Site";
}


sub launch  {  my ($self, $spec)= @_;
  #print "mypscansite::launch(spec=$spec)\n";
  $DB::single=1;
  if (!defined($spec))  { print "WARN mypitem bad launch args\n"; return; }
  $self->setitem($spec);
}

sub setitem { my ($self, $spec)= @_;
  $self->destroy(); # in case re-use.
  $fsite= $self->{fsite}= frdoc->new({spec=>$spec});
  $fsite->readfields();
}

sub populate {  my ($self)= @_;
  return  if $self->pop_links(1);

  my $w= $self->{window};
  my $cr= $w->{crfail}= g::ctlrow($w, 1);
  g::label($cr, "Unable to fetch");
  g::menu_button($cr, "Try without proxy", [\&gnoproxy, $self]);
}

sub gnoproxy { my ($self)= @_;
  my $w= $self->{window};
  $w->{crfail}->destroy();
  return  if $self->pop_links(0);
  g::label($w, "Unable to fetch even without proxy");
  my $fsite= $self->{fsite};
  g::menu_button($w, substr($fsite->{title}, 0, 60), [\&frdoc::launchspec, $fsite->{spec}], 2);
}

sub pop_links { my ($self, $proxy)= @_;
  $proxy= 1  unless defined($proxy);
  my $w= $self->{window};
  my $fsite= $self->{fsite};
  my %hrefs;  
  #foreach $key (keys %$fsite)  { print $key. ' = '. $fsite->{$key}. "\n"; }
  my $title= $fsite->{title};
  my $spec= $fsite->{spec};
  my $hititle;
  return 0  unless $fsite->parse(\%hrefs, \$hititle, $proxy);
  return 0  if $proxy and (0== scalar(%hrefs));

  if (!defined($title) or $title eq '')  {
    $title= files::html_decrappify($hititle);
    frdoc::f_newdoctitle($spec, $title)  if defined($title);
  }
  $title= $spec unless defined($title) and $title ne '';
  my $cr= g::ctlrow($w, 0);
  g::control_button($cr, "E", [\&main::gdoswcmd, 'mypeditrdoc', $spec]);
  g::menu_button($cr, substr($title, 0, 60), [\&frdoc::launchspec, $spec], 2);
  g::label($cr, f::get_thoughtprompt(), 5, 1);
  $scroller= g::frame_scrolled($w);
  my $g=g::grid($scroller, 2);
  $fsite->{slashbase}= files::slashbasefromurl($spec);
  foreach my $url (keys %hrefs)  {
    my $title= files::html_decrappify($hrefs{$url}); $title=~ s|[\r\n]| |iomg;
    next  if length($title)<= 4;
    #print "$title\n";
    $url= $fsite->canonical_url($url);

    g::menu_button($g, substr($title,0,70), [\&glaunch, $spec, $url]);
  }
  return 1;
}

sub glaunch { my ($fromsite, $url)= @_;
  #if ($fromsite=~ m|\.php|io)  {
  #  my $ri= rindex($fromsite, '/');
  #  $fromsite= substr($fromsite, 0, $ri+1);
  #  print "glaunch munge fromsite to: '$fromsite'\n";
  #}
  unless ($url=~ m|^http|io)  {
    print "glaunch URL was: $url\n";
    if ($url=~ m|^\/\/|io)  { # seen on slashdot a lot
      $url= "http:$url";
    } else  {
      $url= "$fromsite$url";
    }
    print "glaunch munge URL to: $url\n";
  }
  g::timer_reset();
  files::launchweb($url);
}

1;

