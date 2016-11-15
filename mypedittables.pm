package mypedittables;
use Tk;
use myf::f;  use myf::frelate; use myf::frdoc;
use mylib::db;  use mylib::dbtable;
use mytk::g;  use mytk::tabpane;  use mytk::records_dbt;
use mylib::rec;
@ISA = ('tabpane');

sub btext { my ($self)=@_;
  return 'Edit Tables';
}

sub populate  {  my ($self)= @_;
  my $w= $self->{window};
  my $cr= g::ctlrow($w);
  g::menu_button($cr, 'Manage DB', \&gui_launch_manager);
  g::menu_button($cr, 'Relate types', [\&pop_dbt, $self, $frelate::trel]);
  g::menu_button($cr, 'Thought prompts', [\&pop_dbt, $self, $f::ttp]);
  g::menu_button($cr, 'Scan sites', [\&pop_dbt, $self, $frdoc::tscansite]);
}

sub pop_dbt { my ($self, $dbt)= @_;
  my $w= $self->{window};
  my $gdbt= $w->{gdbt};
  $gdbt->destroy()  if defined($gdbt);
  #$DB::single = 1;
  $w->{gdbt}= records_dbt->new($w, $dbt);
  $self->{dbt}= $dbt;
  g::timer_reset();
}


sub gui_launch_manager  {
  main::gui_mwgone();  f_launch_manager();  main::gui_mwback();
}

sub f_launch_manager  { db::launch_manager(); }

1;

