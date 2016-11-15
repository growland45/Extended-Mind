package msecentry;
use Tk;  use Date::Format;
use myf::fsecentry;
use mytk::g;  use mytk::tp;  use mytk::section;  use mylib::rec;
@ISA = ('section');


sub launch  {  my ($self, $id)= @_;
  $self->set($id);
}

sub set { my ($self, $id)= @_;
  $self->destroy(); # in case re-use.
  $self->{id}= $id;
}

sub wantctlrow { my ($self)= @_;  return 1;  }
sub pop_ctlrow { my ($self, $cr)= @_;
  $self->read();
  my $type= $self->{type};
  #print "msecentry pop_ctlrow type='$self->{type}'\n";
  my $icr= $self->{w}->{icr}= g::ctlrow($cr, 0);
  g::menu_button($icr, 'Revert', [\&grevert, $self]);
  g::menu_button($icr, 'Save', [\&gsave, $self]);
  g::menu_button($icr, 'Clip', [\&gclip, $self]);

  my $isactiontype= fsecentry::f_isactiontype($self->{type});
  my $ltypes= \@fsecentry::timelesstypes;
  $ltypes= \@fsecentry::actiontypes  if $isactiontype;
  g::optmenu($cr, \$self->{type}, $ltypes, [\&gonselecttype, $self]);

  if ($isactiontype)  {
    g::menu_button($cr, "Today's date", [\&gdate, $self]);
  }  else  {
    g::menu_button($icr, 'Niceify', [\&gniceify, $self]);
  }
  g::menu_button($icr, 'Clear', [\&gclear, $self]);

  $iicr= g::ctlrow($cr, 0);
  g::label($iicr, "Importance ", 0);
  my @impls= ('0', '1', '2', '3');
  $w->{implmenu}= g::optmenu($iicr, \$self->{importance}, \@impls);
  $self->{pself}->gontypechanged($self->{id}, $self->{type});
}

sub pop_decide_delbtn {  my ($self)= @_;
  if ($self->isempty())  { $self->_pop_delbtn_on(); }
  else { $self->_pop_delbtn_off(); }
}

sub _pop_delbtn_on {  my ($self)= @_;
  my $icr= $self->{w}->{icr};
  return  if defined($icr->{delbtn});
  $icr->{delbtn}= g::menu_button($icr, 'DELETE', [\&gdelete, $self]);
}

sub _pop_delbtn_off {  my ($self)= @_;
  my $icr= $self->{w}->{icr};
  return  unless defined($icr->{delbtn});
  $icr->{delbtn}->destroy();
  $icr->{delbtn}= undef;
}


sub pop_body {  my ($self, $b)= @_;
  my $wid= 75;
  $b->{etitle}= g::entry($b, $wid-10, undef, 1, 1);
  $b->{desc}= tp::tpmake($b, \$self->{body}, 23, $wid);
  $self->load($b);
}

sub gclear {  my ($self)= @_;
  g::timer_reset();
  $self->{body}= $self->{title}= '';
  $self->load();
}

sub gdelete { my ($self)= @_;
  g::timer_reset();
  return  unless $self->isempty();
  my $srec= $self->{srec};  return  unless defined($srec);
  $srec->delentry();
  $self->{pself}->launch_clean();
}

sub read { my ($self)= @_;
  #print "msecentry read id='$self->{id}'\n";
  my $srec= fsecentry::fetch_byid($self->{id});
  $self->{srec}= $srec;
  rec::fldscpy($self, $srec, ('type', 'body', 'title'));
  $self->{importance}= rec::recdflt($srec, 'importance', '1');
}

sub grevert {  my ($self)= @_;
  g::timer_reset();
  #print "grevert self=$self fitem=$f_item name=$name\n";
  $self->read();
  my $b= $self->{window}->{body};
  g::entry_set($b->{etitle}, $self->{title});
  tp::tpload($b->{desc});
  $self->pop_decide_delbtn();
}

sub gonselecttype { my ($self)= @_;
  $self->gsave();
  $self->{pself}->gontypechanged($self->{id}, $self->{type});
}

sub gsave  {  my ($self)= @_;
  g::timer_reset();
  $self->unload();
  #$DB::single = 1;
  $self->{srec}->save();
  $self->pop_decide_delbtn();
  $self->{pself}->refresh();
}

#-----------------------------------------------------------------------

sub load {  my ($self, $b)= @_;
  $b= $self->{window}->{body}  unless defined($b);
  g::entry_set($b->{etitle}, $self->{title});
  tp::tpload($b->{desc});
  $self->pop_decide_delbtn();
}

sub unload {  my ($self)= @_;
  my $b= $self->{window}->{body};  my $srec= $self->{srec};
  tp::tpunload($b->{desc});
  $srec->{title}= $self->{title}= g::entry_get($b->{etitle});
  rec::fldscpy($srec, $self, ('type', 'body', 'importance'));
}

sub isempty  { my ($self)= @_;
  $self->unload()  if defined($self->{window}->{body});
  return 0  unless $self->{body} eq '';
  return 0  unless $self->{title}  eq '';
  #$DB::single=1;
  return 1;
}


sub gclip  {  my ($self)= @_;
  g::timer_reset();
  my $b= $self->{window}->{body};
  #print "mypisecentry gclip...b=$b\n";
  $self->{titletext}= g::entry_get($b->{etitle});
  tp::tpunload($b->{desc});
  g::toclip($self->{titletext}. "\n". $self->{body});
}

sub gniceify  {  my ($self)= @_;
  g::timer_reset();
  my $b= $self->{window}->{body};
  tp::tpniceify($b->{desc});
}

sub gdate  {  my ($self)= @_;
  g::timer_reset();
  my $b= $self->{window}->{body};
  my $datestr= time2str("\n%Y-%m-%d ", time);
  tp::tpadd($b->{desc}, $datestr);
}

1;


