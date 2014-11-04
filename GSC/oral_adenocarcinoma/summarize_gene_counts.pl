#!/usr/bin/perl -w

use strict;

my ($expressed_gene_count,$gene_count,$total_sequenced_bases,$sum_coverage,$mean_coverage);

while (<>){
  my @data=split("\t",$_);
  $gene_count++;

  if ($data[5]>0){
    $expressed_gene_count++;
  }

  $total_sequenced_bases+=$data[5];
  $sum_coverage+=$data[7]
}
$mean_coverage=$sum_coverage/$gene_count;

print "$gene_count total genes\n";
print "$expressed_gene_count expressed genes\n";
print "$total_sequenced_bases total sequenced bases\n";
print "$mean_coverage average coverage\n";

exit;
