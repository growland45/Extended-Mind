package records_dbt;
use utf8;
use Encode;
use mylib::dbtable;  use mylib::dbrec;
use mytk::g;  use mytk::records;  use mytk::srecedit;
@ISA = ('records');

sub new { my ($class,
              $parent, $dbt, $addrec_cb) = @_;
  my $self= bless {  }, $class;
  $self->{p}= $parent;
  $self->{fields}= $dbt->{fields};
  $self->{nkey1}= $dbt->{nkey1};  $self->{nkey2}= $dbt->{nkey2};
  $self->{dbt}= $dbt;
  $self->{addrec_cb}= $addrec_cb;
  $self->{cannew}= 1;
  $self->populate($parent);
  return $self;
}

sub populate { my ($self, $p)= @_;
  #print "records_dbt::populate($self, $p)\n";
  my $s= $p->{s}= g::frame_scrolled($p);
  my $ep= $p->{ep}= g::colframe($s);
  my $lp= $p->{lp}= g::colframe($s);
  $self->records::populate($lp);
  $self->load_dbt();
}

sub destroy { my ($self)= @_;
  my $p= $self->{p};
  $p->{s}->destroy();
}

sub refresh { my ($self)= @_;
  my $p= $self->{p};
  $p->{s}->destroy()  if defined($p->{s});
  #$p->{ep}->destroy()  if defined($p->{ep});
  #$p->{lp}->destroy()  if defined($p->{lp});
  $self->populate($p);
}

sub addrec { my ($self, $rec)= @_;
  my $pane= $self->{pane};  
  g::menu_button($pane, 'E', [\&_gedit, $self, $rec]);
  my $fields= $self->{fields};
  foreach my $field (@$fields)  { $self->makecol($field, $rec); }
  my $addrec_cb= $self->{addrec_cb};
  if (defined($addrec_cb))  {  &$addrec_cb($rec, $pane);  }
  g::grid_nextrow($pane);
}

sub load_dbt { my ($self)=@_;
  #print "load_dbt...\n";
  my $cnt= 0;
  my $nkey1= $self->{nkey1};
  $nkey1= $self->{fields}->[0]  unless defined($nkey1);
  $DB::single=1  ;#unless defined($self->{dbt});
  my $sth= $self->{dbt}->prepselect('*', "order by $nkey1");
  return $self->add_sth($sth);
}

sub _gedit {  my ($self, $rec)= @_;
  #$DB::single = 1;
  my $ep= $self->{p}->{ep};
  my $gre= $ep->{gre};  $gre->destroy()  if defined($gre);
  #g::label($ep, '_gedit test');
  $gre= $ep->{gre}= srecedit->new($ep,
                                   {listener=>$self, rec=>$rec,
                                    fields=>$self->{fields}, noid=>1, nkey1=>$self->{nkey1}});
}

sub cb_onnew { my ($self)=@_;
  $self->_gedit();
}

sub cb_onsave {  my ($self, $rec, $isnew)= @_;
  my $dbrec= dbrec->new($rec, $self->{dbt});
  $dbrec->save($isnew, 1);
  $self->refresh();
}

sub cb_ondelete {  my ($self, $rec)= @_;
  my $dbrec= dbrec->new($rec, $self->{dbt});
  $dbrec->delete();
  $self->refresh();
}

1;

