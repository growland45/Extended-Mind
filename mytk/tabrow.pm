package tabrow;
use Tk;  use Module::Load;  use mytk::g;

sub new { my ($class, $args, $paneargs, $istoplevel) = @_;
  my $self= bless {  }, $class;
  $self->{labelvar}= my $labelvar= $args->{labelvar};
  $istoplevel= 0  unless defined($istoplevel);
  $self->{istoplevel}= $istoplevel;
  $self->{mainpanel}= $args->{mainpanel};
  $self->{parent}= my $parent= $args->{parent};
  $self->{paneargs}= $paneargs;
  my $sf= g::ctlrow($parent, 0);
  $sf->{labelvar}= $labelvar;
  g::varlabel($sf, $labelvar, 15)  if defined($labelvar)  and !$istoplevel;
  $self->{sf}= $sf;
  return $self;
}

sub launchsw { my ($self, $class, $k1, $k2, $k3)= @_;
  my $recipe= $self->{'T'. $class};  my $pane= $recipe->{pane};
  $pane= $self->classtab($class, undef, 0, 0)  unless defined($pane);
  die "launchsw can't find pane for '$class'\n"  unless defined($pane);
  $pane->launch($k1, $k2, $k3);
  return $self->_switcher($pane);
}

sub classtab { my ($self, $class, $args, $selected, $visible)= @_;
  load $class;
  my $pane= $class->new($self->{paneargs}, $args);
  $selected= 0  unless defined($selected);
  $visible= 1  unless defined($visible);
  $pane->{tabrow}= $self;
  $pane->{mainpanel}= $self->{mainpanel};
  if ($visible)  {  $self->_addbtn($pane, $selected);  }
  my %recipe= (pane=>$pane, args=>$args, visible=>$visible);
  $self->{'T'. $class}= \%recipe  unless defined($self->{'T'. $class});
  #print "classtab addded '$class\n";
  return $pane;
}

sub _addbtn { my ($self, $pane, $selected)= @_;
  my $sf= $self->{sf};
  $btext= $pane->btext();
  #my $tabcell= $pane->{tabcell}= g::cell($sf);
  my $btn= g::menu_button($sf, $pane->btext(), [\&_switcher, $self, $pane]);
  #my $btn= $tabcell->{btn}= g::menu_button($tabcell, $pane->btext(), [\&_switcher, $self, $pane]);
  if ($selected) { $self->_switcher($pane); }
}

sub _switcher  {  my ($self, $pane)= @_; # mypitem
  my $labelvar= $self->{labelvar};
  my $currenttab= $self->{currenttab};
  $currenttab->onleave()  if defined($currenttab);
  #print "switcher $currenttab -> $pane\n";
  $pane->make();  $self->{currenttab}= $pane;
  my $btext= $pane->btext();
  g::mwtitlesuffix($btext)  if $self->{istoplevel};
  $$labelvar= $btext  if defined($$labelvar);
  #print "scratch='$scratch' vs '$$labelvar'\n";
}

sub refresh { my ($self)= @_;
  my $currenttab= $self->{currenttab};
  return  unless defined($currenttab);
  $currenttab->onleave();
  $currenttab->make();
}

1;

