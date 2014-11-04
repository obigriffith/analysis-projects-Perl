#!/usr/bin/perl -w

use strict;
use Data::Dumper;

my $GOgenesfile="PopulationGeneAssoc_IEA";
my $genepairfile="common_gene_pairs.txt";
my %GOgenes;

open (GOFILE, $GOgenesfile) or die "can't open $GOgenesfile\n";
while (<GOFILE>){
  if($_=~/(\d+)\s+GO/){
    $GOgenes{$1}++;
  }
}
close GOFILE;


open (GENEPAIRS, $genepairfile) or die "can't open $genepairfile\n";
while (<GENEPAIRS>){
  if ($_=~/(\d+)\s+(\d+)/){
    if ($GOgenes{$1} && $GOgenes{$2}){
      print;
    }
  }
}
close GENEPAIRS;
