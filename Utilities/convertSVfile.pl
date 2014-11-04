#!/usr/bin/env genome-perl

use strict;
use warnings;

while (<>){
  chomp $_;
  if ($_=~/^chromosome_name/){next;} #skip header
  if ($_=~/^\#CHR1/){next;} #skip header
  my @data=split("\t", $_);
  my $type = $data[6];
  my $size = $data[8];
  if ($type eq 'ITX' || $type eq 'CTX' || $type eq 'INS') {$size=-$size;}
  print join("\t",@data[0..6]),"\t$size","\n";
}

