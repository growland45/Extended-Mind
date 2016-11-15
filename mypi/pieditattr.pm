package pieditattr;
use Tk;
use myf::fattr; use mypitem;  use mytk::g;  use mytk::tabpane;
@ISA = ('tabpane');

#-----------------------------------------------------------------

sub btext { my ($self)=@_;
  return "Edit Attribute";
}

sub launch  {  my ($self, $ikey, $id)= @_;
  my $args= {id=>$id};
  $self->destroy(); # in case re-use.
  my $fattr= $self->{fattr}= fattr->new($args);
  $fattr->readfields();
  #print "pieditattr id=$id type=$fattr->{type}\n";
  return $fattr;
}
  
sub populate {  my ($self)= @_;
  $self->{isnew}= 0  unless defined($self->{isnew});
  my $w= $self->{window};
  my $cr= $w->{cr}= g::ctlrow($w);
  g::menu_button($cr, 'Save', [\&g_save, $self]);
  g::menu_button($cr, 'Delete', [\&g_delete, $self]) unless $self->{isnew};

  my $cr2= g::ctlrow($w);
  my $fattr= $self->{fattr};
  if ($self->{isnew})  {
    $w->{type}= g::entry($cr2, 20, $fattr->{type}, 1);
    g::label($cr2, ':', 5);
  }  else {  g::label($cr2, $fattr->{type}.':', 5);  }
  $w->{value}= g::entry($cr2, 70, $fattr->{value}, 1, 1, 1);
}

sub g_save  { my ($self)= @_;
  g::timer_reset();
  my $w= $self->{window};
  my $fattr= $self->{fattr};
  $fattr->{type}= g::entry_get($w->{type}) if $self->{isnew};
  $fattr->{value}= g::entry_get($w->{value});
  $fattr->save($self->{isnew});
  mypitem::gdoswcmd('pimain');
}

sub g_delete  { my ($self)= @_;
  $self->{fattr}->delentry();
  mypitem::gdoswcmd('pimain');
}

1;

