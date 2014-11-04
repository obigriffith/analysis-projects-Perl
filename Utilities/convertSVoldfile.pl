#!/usr/bin/env genome-perl

use strict;
use warnings;

while (<>){
  chomp $_;
  if ($_=~/\#ID/){next;} #skip header
  my @data=split("\t", $_);
  my $type = $data[7];
  my $size = $data[9];
  if ($type eq 'ITX' || $type eq 'CTX' || $type eq 'INS') {$size=-$size;}
  print join("\t",@data[1..7]),"\t$size","\n";
}

