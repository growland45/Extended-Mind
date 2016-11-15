package mrelates;
use Tk;
use myf::fitem; use myf::frelate; use myf::f;  use myf::frdoc;
use mytk::g;  use mytk::section;  use mypitem;
@ISA = ('section');


sub makectlrow  { my ($self)= @_;
}


sub pop_body { my ($self, $body)= @_;
  $self->{wide}= 0  unless defined($self->{wide});
  my $wide= $self->{wide};
  my $krfrom= $self->{krfrom};
  return  unless scalar(keys %$krfrom)> 0;

  my $fromwid= 1;  $fromwid= 3 if $wide;
  #g::label($linkspane, $name. " links from:", undef, 1);
  my $fromgrid= g::grid($body, 2*$fromwid);
  my $mgrid= g::grid($body, 2*$fromwid);
  my $cnt= 0;
  foreach $key (sort keys %$krfrom)  {
    #print "mrelate key='$key'\n";
    $cnt++;
    my $frelate= $krfrom->{$key};
    my $destgrid= $fromgrid;  $destgrid= $mgrid  if $frelate->{rtcat} eq 'M';
    $self->_pop_relate($destgrid, $frelate);
  }
  $self->{cnt}= $cnt;
}

sub _pop_relate { my ($self, $fromgrid, $frelate)= @_;
  my $fsz= $frelate->rank();  $fsz= 0  if $fsz> 0;
  my $wide= $self->{wide};
  my $twid= 37;  $twid= 22  if $wide;
  my $dwid= 25;  $dwid= 17  if $wide;
  my $rwid=20;   $rwid= 17  if $wide;
  my $key1= $frelate->{key1};  my $key2= $frelate->{key2};
  my $cr= g::rowframe($fromgrid);
  my $lbtext= substr($frelate->{name1}, 0, $twid- $fsz*3);
  main::glaunchbutton($cr, $lbtext, $key1, $fsz+ $frelate->{importance});

  my $q= substr($frelate->{desc}, 0, $rwid);
  glaunchrelatebutton($cr, $q, $key1, $key2, $fsz);

  my $maindoc= $frelate->{maindoc};
  if (defined($maindoc) and $maindoc ne '')  {
    mypitem::gpopmaindoc($maindoc, $fromgrid, $dwid, $fsz);
    return;
  }

  my $body= $frelate->{body};
  if (defined($body)  and $body ne '')  {
    g::label($fromgrid, substr($body, 0, $dwid), 0, $fsz);
    return;
  }

  my $fitem= $self->{pimain}->{fitem};  my $name= $fitem->{name};
  my $name= $fitem->{name};
  g::label($fromgrid, substr($name, 0, $dwid), 1, $fsz);
}


sub glaunchrelatebutton { my ($parent, $btext, $key1, $key2, $fsz)= @_;
  return g::control_button($parent, $btext, 
                        main::glaunchswcmd('myprelate', $key1, $key2), $fsz);
}


1;


