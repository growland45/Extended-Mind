package htmlout;

1;

our $OUT;

sub hopen { my ($fspec)= @_;
  open ($OUT, '>'. $fspec) or die;
}

sub hclose {
  close($OUT);
}

sub hwrite { my ($html)= @_;
  print $OUT $html if defined($html);
}

sub header { my ($title, $ctags)= @_;
  print $OUT "<html><head><title>$title</title><head>\n";
  print $OUT "<body $ctags>\n";

}

sub footer {
  print $OUT "</body></html>\n";
  close $OUT;
}

sub theader { my ($attr)= @_;
  $attr= 'width=100% cellpadding=4 border=1'  unless defined($attr);
  print $OUT "<table $attr>\n";
}

sub tfooter {
  print $OUT "</table>\n";
}

sub tdsection {my ($callback, $arg, $col, $attrs)= @_;
  $attrs= 'valign=top'  unless defined($attrs);
  print $OUT "<td $attrs>\n";
  &$callback($arg, $col);
  print $OUT "</td>\n";
}

sub tr {  print $OUT "<tr></tr>\n";
}

1;

