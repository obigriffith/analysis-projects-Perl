#!/usr/local/bin/perl -w

use strict;

my @list = `ls`;

foreach my $file(@list){
  if ($file =~ /^.+\.fasta/){
    `fasta2Phd.perl $file`;
  }
}

exit;

