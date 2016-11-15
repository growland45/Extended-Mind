package myserelate;
use Tk;
use myf::fitem;  use myf::frelate;
use mylib::db;  use mytk::g;  use mytk::section;
@ISA = ('section');

sub pop_body { my ($self, $body)= @_;
  my $frelate= $self->{frelate};
  my $wid= $self->{wid};
  my $reltypes= frelate::reltypelist();
  @opts=();
  foreach my $opt (sort keys %$reltypes)  { push @opts, $opt; } 
  my $cr= g::ctlrow($body, 0);
  g::label($cr, "Verb:");
  $self->{desc}= g::entry($cr, $wid/2);

  $self->{detail}= g::entry($body, $wid);
  my $relf= g::rowframe($body);
  my $ga= g::grid($relf, 2);  g::label($ga, 'Acting');
  my $gp= g::grid($relf, 1);  g::label($gp, 'Passive');
  my $gm= g::grid($relf, 1);  g::label($gm, 'Membership');
  foreach my $opt (sort keys %$reltypes)  {
    my $rtrec= $reltypes->{$opt};  my $rtcat= $rtrec->{rtcat};
    my $dg= $gp;  $dg= $ga  if $rtcat eq 'A';  $dg= $gm  if $rtcat eq 'M';
    g::menu_button($dg, $opt, [\&_seldesc, $self, $opt], 0);
  } 
}

sub unload_tofrelate  { my ($self)= @_;
  my $frelate= $self->{frelate};
  $frelate->{desc}= g::entry_get($self->{desc});
  $frelate->{body}= g::entry_get($self->{detail});
}

sub load_fromfrelate  { my ($self)= @_;
  my $frelate= $self->{frelate};
  my $desc= $self->{desc};  g::entry_set($desc, $frelate->{desc})  if defined($desc);
  my $detail= $self->{detail};  g::entry_set($detail, $frelate->{body})  if defined($detail);
}

sub _seldesc { my ($self, $desctext)= @_;
  g::entry_set($self->{desc}, $desctext);
  $self->unload_tofrelate();
}


1;


