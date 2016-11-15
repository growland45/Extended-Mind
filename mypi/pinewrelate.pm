package pinewrelate;
use Tk;
use myf::fitem;  use myf::frelate;  use mypitem;
use mytk::g;  use mytk::tabpane;
use myserelate;
@ISA = ('tabpane');

sub btext { my ($self)=@_;
  return '+Relate';
}

sub set { my ($self, $fitem)= @_;
  $self->destroy(); # in case re-use.
  $self->{fitem}= $fitem;
}

sub populate {  my ($self)= @_;
  my $w= $self->{window};
  my $fitem= $self->{fitem};  my $key= $fitem->{key}; # from paneargs
  my $twopanes= g::rowframe($w);
  my $lpane= g::colframe($twopanes);
  my $itemframe= g::colframe($twopanes);

  my $wid= 30;
  my $frelate= $self->{frelate}= frelate->new({key1=>$key, desc=>'', body=>''});
  my $scroller= g::frame_scrolled($lpane);
  $w->{serelate}= myserelate->new($scroller, {frelate=>$frelate, wid=>30});

  my %ritems= ();
  my $i= 0;  my $max= 15;
  my $recentitems= mypitem::recentitems();
  foreach my $rikey (keys %$recentitems)  { 
    next  if $fitem->{key} eq $rikey;
    next  if $fitem->relatedto($rikey);
    my $rifitem= fitem->new({key=>$rikey});
    $rifitem->readfields();
    my $btext= $rifitem->{name}; $btext= substr($btext, 0, 30);
    $ritems{$btext}= $rikey;
    $i++;  #TODO last if $i>= $max;
  }

  my $is= g::frame_scrolled($itemframe);
  my $ig= g::grid($is, 2);
  foreach my $btext (sort { "\L$a" cmp "\L$b" } keys %ritems)  {
    my $rikey= $ritems{$btext};
    g::menu_button($ig, $btext, $self->gnewrelatecmd($rikey));
  }
}

sub gnewrelatecmd { my ($self, $rikey)= @_;
  return [\&relatetoitem, $self, $rikey];
}

sub relatetoitem { my ($self, $rikey)= @_;
  my $w= $self->{window};
  $w->{serelate}->unload_tofrelate();
  my $frelate= $self->{frelate};
  $frelate->{key2}= $rikey;
  $frelate->newentry();
  #$self->refresh();
  mypitem::gdoswcmd('pimain');
}

1;

