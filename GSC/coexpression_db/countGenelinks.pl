#!/usr/local/bin/perl -w

use strict;

my %genelinks;

while (<>){
  if ($_=~/(\S+)\s+(\S+)\s+/){
    $genelinks{$1}++;
    $genelinks{$2}++;
  }
}

my %linkdist;
foreach my $gene (keys %genelinks){
  my $linkcount = $genelinks{$gene};
  $linkdist{$linkcount}++;
}

foreach my $linkcount (sort{$a<=>$b} keys %linkdist){
print "$linkcount\t$linkdist{$linkcount}\n";
}
