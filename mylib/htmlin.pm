package htmlin;
use mylib::net;
use base "HTML::Parser";

sub set_ahref_callback { my ($self, $cb, $arg0)= @_;
  #print "htmlin::set_ahref_callback(cb=$cb)\n";
  $self->{ahref_cb}= $cb;
  $self->{ahref_cb_arg0}= $arg0;
}

sub parse_geturl { my ($self, $url, $proxy, $timeout)=@_;
  my ($html, $base)= net::httpget_base($url, $timeout, $proxy);
  return  0 unless defined($html);
  #print $html;
  $self->{intitle}= 0;
  $self->{base}= $base;
  $self->parse($html);
  return 1;
}

sub start { my ($self, $tag, $attr, $attrseq, $origtext) = @_;
  #print $tag;
  if ($tag =~ /^a$/io and defined($attr->{'href'})) { return $self->start_a_href($attr, $attrseq, $origtext); }
  if ($tag =~ /^title/io) { $self->{intitle}= 1; return; }
  return $self->start_misc($tag, $attr, $attrseq, $origtext);
}

sub start_a_href { my ($self, $attr, $attrseq, $origtext) = @_;
  #print " a href   ";
  $self->{a_href}= $attr->{'href'};
  $self->{href_title}= '';
}

sub start_misc { my ($self, $tag, $attr, $attrseq, $origtext) = @_;
}

sub text { my ($self, $text) = @_;
  if (defined($self->{a_href}))  { $self->{href_title}.= $text. ' '; }
  elsif ($self->{intitle})  { $self->{title}= $text; }
  else  { return $self->text_misc($text); }
}

sub text_misc { my ($self, $text) = @_;
  #print $text;
}

sub end { my ($self, $tag, $origtext) = @_;
  my $a_href= $self->{a_href};
  if ($tag =~ /^a$/ and defined($a_href)) {
    my $title= $self->{href_title};
    my $cb= $self->{ahref_cb};
    #print "htmlin::end cb=$cb, title='$title'\n";
    if (defined($cb))  {
      return &$cb($self->{ahref_cb_arg0}, $a_href, $title);
    }
  } elsif ($tag =~ m|title|io)  {
    $self->{intitle}= 0;  #print "'$self->{title}'\n";
  }
  return $self->end_misc($tag, $origtext);
}


sub end_misc { my ($self, $tag, $origtext) = @_;
}

1;

