package pisections;
use Tk;
use myf::fitem;  use mypitem;  use myf::fsecentry;
use mytk::g;  use mytk::tabpane;
use mypi::msecentry;
@ISA = ('tabpane');

sub new { my ($class, $cargs, $aargs) = @_;
  #$DB::single = 1;
  my $self= $class->SUPER::new($cargs, $aargs);
  $self->{isaction}= 0;
  $self->{type}= 'notes';
  #print "pisections:new self=$self pitem=$self->{pitem}\n";
  return $self;
}

sub btext {  my ($self)= @_;  return 'Notes';  }

sub typeslist {  my ($self)= @_;  return \@fsecentry::timelesstypes;  }

sub launch_clean { my ($self)= @_;
  $self->{id}= $self->{srec}= undef;
  $self->refresh();
}

sub launch { my ($self, $id)= @_;
  #$DB::single = 1;
  $self->{pitem}->{srec}= undef  if defined($id);
  $id= $self->{id}  unless defined($id);
  $self->{id}= $id;  #print "pisections launch id=$id\n";

  my $w= $self->{window};
  return  unless defined($w); # from gtabrow

  $w->{se}->destroy()  if defined($w->{se});
  return  unless defined($id);
  $w->{se}= msecentry->new($w->{rf}, {id=>$id, pself=>$self, type=>$self->{type}});
}

sub populate {  my ($self)= @_;
  #$DB::single = 1;
  my $w= $self->{window};
  my $type= $self->{type};
  my $srec= $self->{pitem}->{srec};
  $self->{id}= $srec->{id}  if !defined($self->{id}) 
                               and defined($srec) and $srec->isactiontype()== $self->{isaction};
  #print "pisections::populate self=$self pitem=$self->{pitem} id=$self->{id} srec=$srec type=$type\n";

  my $prow= g::rowframe($w);
  my $fitem= $self->{fitem};
  my $cf= g::colframe($prow);
  my $cr= g::ctlrow($cf, 1);
  my $typeslist= $self->typeslist();
  g::label($cr, $self->btext());
  if (defined($typeslist))  {
    #$DB::single = 1;
    g::optmenu($cr, \$self->{type}, $typeslist, [\&gonselecttype, $self], 2);
    #my $tcnt= 0;
    #foreach my $typeopt (@$typeslist)  {
    #  g::menu_button($cr, $typeopt, [\&gonselecttype, $self, $typeopt]);
    #  $tcnt++;  $last if $tcnt>= 4;
    #}
  }
  $self->{slist}= g::frame_scrolled($cf);
  $self->pop_plist();
  $w->{rf}= g::colframe($prow);
  $id= $self->{id}; # may have changed
  #print "pisections::populate ...now id=$id\n";
  if (defined($id)  and $id ne '')  {  $self->launch($id);  }
}

sub pop_plist {  my ($self)= @_;
  my $plist= $self->{plist}= g::grid($self->{slist}); # grid gets better layout from Tk.
  my $type= $self->{type};  my $typeslist= $self->typeslist();
  #print "pisections::pop_plist type=$type\n";
  $self->popsec($plist, $type); # always first
  if (defined($typeslist))  {
    foreach my $othertype (@$typeslist)  {
      next  if $othertype eq $type;
      $self->popsec($plist, $othertype);
    }
  }
}

sub popsec { my ($self, $p, $type)= @_;
  my $fitem= $self->{fitem};
  my $cr= g::ctlrow($p);
  g::label($cr, $type);
  g::menu_button($cr, "NEW", [\&gnewsecentry, $self, $type], 0);
  g::menu_button($cr, "Clip all", [\&gclip, $self, $type], 0);
  g::menu_button($cr, "Prune", [\&gprune, $self, $type], 0);
  my $grid= g::grid($p);
  my %secs;  $fitem->get_sectionlist($type, \%secs);
  my $firstid= undef, $lastid= undef; # because Perl may otherwise reuse old value!
  foreach my $key (sort keys %secs)  {
    my $srec= $secs{$key};
    my $fsz= $srec->rank();
    $fsz++  if ($srec->{lb}== 0); # empty section item, see fsecentry
    $fsz++;
    if (!defined($self->{id}))  {
      # maybe choose item to bring up...
      my $srecid= $srec->{id};
      $firstid= $srecid  unless defined($firstid);
      $lastid= $srecid;

      if ($type eq $self->{type} and $srec->{lb}== 0) { # empty section item
        $self->{id}= $srecid  # convenience for writing projects
          unless $self->{isaction};
      }
    } 
    g::menu_button($grid, substr($srec->{title}, 0, 40), $self->glaunchcmd($srec), $fsz);
  }

  if (!defined($self->{id}))  {
    if ($type eq 'log')  { $self->{id}= $lastid; }
    else  { $self->{id}= $firstid; }
    #print "CHOOSING id=$self->{id} type=$type\n";
  }
}


sub glaunchcmd { my ($self, $srec)= @_;
  return [\&launch, $self, $srec->{id}];
}

sub gnewsecentry { my ($self, $type)= @_;
  my $fitem= $self->{fitem};
  my $id= $self->{id}= $fitem->new_secentry($type);
  #print "gnewsecentry id= $id\n";
  $self->refresh();
  $self->launch($id);
}

sub gclip  { my ($self, $type)= @_;
  #print "pisections::gclip($type)\n";
  my $ctext= '';
  my $fitem= $self->{fitem};
  my %secs;  $fitem->get_sectionlist($type, \%secs);
  foreach my $skey (sort keys %secs)  {    #print "gclip key=$skey\n";
    my $srec= $secs{$skey};    #print "   id=$srec->{id}\n";
    my $secrec= fsecentry::fetch_byid($srec->{id});    #print "     title=$secrec->{title}\n";
    my $stitle= secrec->{title};
    $ctext.= $stitle. "\n"  unless $stitle=~ m|^\.|o;;
    $ctext.= $secrec->{body}. "\n\n";
  }
  g::toclip($ctext);
}

sub gontypechanged { my ($self, $secid, $newtype)= @_;
  return  if $newtype eq $self->{type}; # not actually changed.
  $self->gonselecttype($newtype);
}

sub gonselecttype { my ($self, $type)= @_;
  $self->{type}= $type  if defined($type);
  $self->{plist}->destroy()  if defined($self->{plist});
  $self->pop_plist();
}

sub gprune { my ($self, $type)= @_;
  #TODO: use $type and $fitem
  fsecentry::prune_sections();
  $self->refresh();
}


1;


