package mypactions;
use Tk;
use String::Util 'trim';
use mylib::db;  use myf::f;  use myf::fitem;  use mypitem;
use mytk::g;  use mytk::gcore;  use mytk::tabpane;
@ISA = ('tabpane');

sub btext { my ($self)=@_;  return "Action Items";  }

sub populate  { my ($self)= @_;
  my $w= $self->{window};

  my $scroller= g::frame_scrolled($w);
  my $prow= g::rowframe($scroller);
  my $dapane= g::colframe($prow);
  my $tdpane= g::colframe($prow);
  my %lw=();
  fsecentry::f_searchwait(\%lw, 30);

  my $rows= 13;  $rows-= 2  if scalar(keys %lw)> 0; 

  #main::g_popflag($tdpane, 'actfocus', 'Action Focus', 26);
  g::label($tdpane, 'To do (partial):', undef, 2);  $rrows--;
  my %l;
  fsecentry::f_searchwriteups(\%l, $rows/3);
  fsecentry::f_searchempties(\%l, $rows/2);
  fsecentry::f_searchtodo(\%l);
  main::g_popgrid($tdpane, \%l, 0, 1, $rows-2);
  g::menu_button($tdpane, 'MORE', main::glaunchswcmd('mypempties'), 2);

  my %ld=();  fsecentry::f_searchdates(\%ld, 30);
  if (scalar (keys %ld))  {  $self->pop_datedacts($dapane, $rows, \%ld);  }
  else  {  g::label($dapane, 'No dated action items');  }

  if (scalar(keys %lw))  {
    g::label($scroller, "Waiting on:");
    main::g_popgrid($scroller, \%lw, 0, 2);
  }

  g::label($scroller, f::get_thoughtprompt(), 1);
}

$bsz= 30; $btsz= 60;

sub pop_datedacts  { my ($self, $pane, $rows, $ld)=@_;
  g::label($pane, 'Dated action items:', undef, 2);

  my $dagrid= g::grid($pane, 2);
  my $fsz= $gcore::maxfont;
  my $cnt= 0;

  foreach my $key (sort keys %$ld)  {
    my $fse= $ld->{$key};
    main::g_pop_section($fse, $dagrid, 0, $fsz);
    if ($fsz> 0)  { $fsz--; }
    $cnt++;  last  if $cnt>= $rows;
  }
  return $cnt;
}

1;

