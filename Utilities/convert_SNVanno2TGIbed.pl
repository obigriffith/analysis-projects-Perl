#!/usr/bin/env genome-perl

use strict;
use warnings;
use Genome::Info::IUB;

while (<>){
  chomp $_;
  if ($_=~/^chromosome_name/){next;} #skip header
  my @data=split("\t", $_);
  my $ref = $data[3]; 
  my $var = $data[4]; 
  my $iub = Genome::Info::IUB->iub_for_alleles($ref,$var); 
  $data[4]=$iub; 
  print join("\t",@data[0..2]),"\t$data[3]/$data[4]\t-\t-","\n";
}

