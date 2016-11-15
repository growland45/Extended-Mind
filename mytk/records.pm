package records;
use utf8;
use Encode;
use mytk::g;  use mytk::tp;  use mylib::dbtable;

sub new { my ($class,
              $parent, $fields, $addrec_cb, $cannew) = @_;
  my $self= bless {  }, $class;
  $self->{fields}= $fields;
  $cannew= 0  unless defined($cannew);  $self->{cannew}= $cannew;
  $self->{addrec_cb}= $addrec_cb;
  $self->populate($parent);
  return $self;
}

sub populate { my ($self, $parent)= @_;
  my $pane= $self->{pane}= g::grid($parent, 10);  $fsz= 1;
  my $fsz= 1;
  if ($self->{cannew})  { g::menu_button($pane, 'New', [\&_gnew, $self], $fsz)  }  
  else  {  g::label($pane, ' '); }
  my $fields= $self->{fields};
  foreach my $field (@$fields)  { g::label($pane, $field, undef, $fsz); }
  g::grid_nextrow($self->{pane});
}

sub destroy { my ($self)= @_;
  $self->{pane}->destroy();
}

sub add_sth  { my ($self, $sth)= @_;
  my $cnt= 0;
  while (my $rec= dbtable::fetchselect($sth))  {
    last  unless defined($rec);
    #print "add_sth addrec $rec->{reltype}\n";
    $self->addrec($rec);
    $cnt++;
  }
  dbtable::finishselect($sth);
  return $cnt;
}

sub addrec { my ($self, $rec)= @_;
  my $pane= $self->{pane};  
  my $fields= $self->{fields};
  g::menu_button($pane, 'Clip', [\&clipcopy, $self, $rec]);
  foreach my $field (@$fields)  { $self->makecol($field, $rec); }
  my $addrec_cb= $self->{addrec_cb};
  if (defined($addrec_cb))  {  &$addrec_cb($rec, $pane);  }
  g::grid_nextrow($pane);
}

sub addhash { my ($self, $hash, $cmax)=@_;
  my $cnt= 0;
  foreach my $k (sort keys %$hash)  {
    my $rec= $hash->{$k};
    #print " chpcharstats $k\n";
    $self->addrec($rec);
    $cnt++;  last  if defined($cmax) and $cnt>= $cmax;
  }
  return $cnt;
}

sub destroy { my ($self)= @_;
  return  unless defined $self->{pane};
  $self->{pane}->destroy();
  $self->{pane}= undef;
}

sub makecol { my ($self, $fname, $rec)= @_;
  return  unless defined($fname);
  return  undef  unless defined($fname);
  my $pane= $self->{pane};
  #print "makecol '$fname' '". $rec->{$fname}. "'\n";
  my $text= $rec->{$fname};
  my $fsz= $self->{fsz};
  if (!defined($fsz))  { $fsz= 1;  $fsz= 3  if g::is_string_chinese($text); }
  g::label($pane, $text, 1, $fsz);
}

sub makecol_edit { my ($self, $fname, $rec)= @_;
  return  unless defined($fname);
  my $pane= $self->{pane};
  tp::tpmake($pane, \$rec->{$fname}, 30, 3);
  return $cr;
}

sub clipcopy  { my ($self, $rec)= @_;
  my $text= '';  my $fields= $self->{fields};
  foreach my $field (@$fields)  {    $text.= $rec->{$field}."\n";  }
  g::toclip($text);
}

sub _gnew { my ($self)=@_;
  $self->cb_onnew();
}

1;

