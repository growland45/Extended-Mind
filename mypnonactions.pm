package mypnonactions;
use Tk;
use myf::f;  use myf::fitem;  use mypitem;
use mytk::g;  use mytk::tabpane;
@ISA = ('tabpane');

sub btext { my ($self)=@_;
  return 'Ponder Items';
}

sub populate { my ($self)= @_;
  my $w= $self->{window};
  #print "gui_fillsnonaction\n";
  my $scroller= g::frame_scrolled($w);
  my $prow= g::rowframe($scroller);
  my $lpane= g::colframe($prow);
  my $qpane= g::colframe($prow);

  main::g_popflag($lpane, 'ponderfocus', 'Ponder Focus', 45);

  my $cr= g::ctlrow($qpane);
  g::label($cr, 'Items with questions:', 5, 2);
  g::label($cr, f::get_thoughtprompt(), 5, 1);

  # new style...
  my $bg= $w->{bg}= g::grid($qpane, 2, 21);
  my %listbyspec;
  fsecentry::f_questions(\%listbyspec, 30);
  foreach my $key (sort keys %listbyspec)  {
    _pop_question($listbyspec{$key}, $bg);
  }
}

sub _pop_question  { my ($fse, $g)=@_;
  my $iname= fitem::f_textfromkey($fse->{ikey}, 25);
  g::label($g, $iname, 0); 
  my $btext= substr($fse->{title}, 0, 45);
  my $id= $fse->{id};  #print "gui_isearch: '$id'\n";
  main::glaunchsecbtn($g, $btext, $id, $fse->{importance});
}



1;

