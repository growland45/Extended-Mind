package srecedit;
use Tk;
use mylib::db;  use mylib::dbtable;  use mytk::g;  use mytk::section;
@ISA = ('section');


sub wantctlrow { my ($self)= @_;  return 1;  }

sub pop_ctlrow  { my ($self, $cr)= @_;
  g::menu_button($cr, 'Save', [\&_gsave, $self]);
  my $rec= $self->{rec};
  my $isnew= $self->{isnew}= !defined($rec);
  g::menu_button($cr, 'Revert', [\&revert, $self])  unless $isnew;
  g::menu_button($cr, 'Delete', [\&_gdelete, $self])  unless $isnew;
}

sub pop_body { my ($self, $b)= @_;
  #$DB::single = 1;
  my $rec= $self->{rec};
  my $fields= $self->{fields};
  my $noid= $self->{noid};  $noid= 0  unless defined($noid);
  my $g= g::grid($b, 2);
  my $isnew= $self->{isnew}= !defined($rec);
  if ($isnew)  {
    my %nrec;
    my $rec= $self->{rec}= \%nrec;
    foreach my $field (@$fields)  {  $rec->{$field}= '';  }
  }
  my $nkey1= $self->{nkey1};   #print "srecedit::pop_body nkey1='$nkey1'\n";
  foreach my $field (@$fields)  {
    g::label($g, $field);
    my $i= ($field eq $nkey1);  $i=1  if ($field eq $self->{nkey2});
    $i= 0  if $isnew;
    if ($i)  {
      g::label($g, $rec->{$field});
    }  else  {
      next  if $noid  and $field eq 'id';
      my $e= g::entry($g, 50, $rec->{$field}, undef, 1, 1);
      $b->{"E.$field"}= $e; 
    }
  }
}

sub revert { my ($self)= @_;
  my $b= $self->{window}->{body};
  my $rec= $self->{rec};
  my $fields= $self->{fields};
  foreach my $field (@$fields)  {
    my $e= $b->{"E.$field"};
    next  unless defined($e);
    g::entry_set($e, $rec->{$field});
  }
}

sub unload { my ($self)= @_;
  my $b= $self->{window}->{body};
  my $rec= $self->{rec};
  my $fields= $self->{fields};
  foreach my $field (@$fields)  {
    my $e= $b->{"E.$field"};
    next  unless defined($e);
    $rec->{$field}= g::entry_get($e);
  }
}

sub _gsave { my ($self)= @_;
  $self->unload();
  $self->{listener}->cb_onsave($self->{rec}, $self->{isnew});
}

sub _gdelete { my ($self)= @_;
  $self->{listener}->cb_ondelete($self->{rec});
  #$self->{window}->destroy()  if defined($self->{window});
  $self->{window}= undef;
}

1;

