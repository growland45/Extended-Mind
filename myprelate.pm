package myprelate;
use Tk;
use myf::frelate;
use mylib::db;  use mytk::g;  use mytk::tabpane;
use mypitem; use myserelate;
@ISA = ('tabpane');

#@opts= ('', 'a kind of', 'aspect of', 'category of', 'concept in',
#        'enables', 'for', 'is a', 
#        'opposes', 'part of', 'relevant to', 'requires');

#-----------------------------------------------------------------

sub btext { my ($self)=@_;
  return "Relate";
}

sub launch  {  my ($self, $key1, $key2)= @_;
  #print "mypitem::launchitem key='$key'\n";
  my $args= {key1=>$key1, key2=>$key2};
  $self->setrelate($args);
}

sub setrelate { my ($self, $args)= @_;
  $self->destroy(); # in case re-use.
  my $frelate= $self->{frelate}= frelate->new($args);
  $frelate->readfields();
}

sub populate {  my ($self)= @_;
  #print "myprelate::populate...\n";
  my $w= $self->{window};
  my $frelate= $self->{frelate};
  $frelate->readfields();

  my $p= $w->{pane}= g::colframe($w);
  my $cr= g::ctlrow($p);
  my $cr1= g::ctlrow($cr, 0);
  main::glaunchbutton($cr1, $frelate->{name1}, $frelate->{key1});
  g::label($cr1, '=>');
  main::glaunchbutton($cr1, $frelate->{name2}, $frelate->{key2});
  g::menu_button($cr, 'Revert', [\&revert, $self]);
  g::menu_button($cr, 'Save', [\&save, $self]);
  g::menu_button($cr, 'Delete', [\&g_delete, $self]);

  my $scroller = g::frame_scrolled($p);
  $w->{serelate}= myserelate->new($scroller, {frelate=>$frelate, wid=>80});
  $self->fillfields();

  #print "...myprelate::populate\n";
  return $w;
}

sub revert {  my ($self)= @_;
  g::timer_reset();
  $self->readfields();
}

sub readfields { my ($self)= @_;
  $self->{frelate}->readfields();
  $self->fillfields();
}

sub save  { my ($self)= @_;
  g::timer_reset();
  my $frelate= $self->{frelate};
  my $serelate= $self->{window}->{serelate};
  $serelate->unload_tofrelate();
  $frelate->save();
}

sub g_delete  { my ($self)= @_;
  g::timer_reset();
  my $frelate= $self->{frelate};
  my $serelate= $self->{window}->{serelate};
  $serelate->unload_tofrelate();
  return  if $frelate->{desc}  ne '';
  return  if $frelate->{body}  ne '';

  # make rewiring relates easier...
  mypitem::logitem($frelate->{key1});
  mypitem::logitem($frelate->{key2});

  $frelate->delentry();

  #main::gdoswcmd('mypitem', $frelate->{key1});
  my $w= $self->{window};
  $w->{pane}->destroy();
  my $cr= g::ctlrow($w);
  g::label($cr, ' Back to ');
  main::glaunchbutton($cr, $frelate->{name1}, $frelate->{key1});
  g::label($cr, ' or ');
  main::glaunchbutton($cr, $frelate->{name2}, $frelate->{key2});

}

sub fillfields { my ($self)= @_;
  #print "myprelate::fillfields...\n";
  my $serelate= $self->{window}->{serelate};
  $serelate->load_fromfrelate();
  #print "...myprelate::fillfields\n";
}

1;

