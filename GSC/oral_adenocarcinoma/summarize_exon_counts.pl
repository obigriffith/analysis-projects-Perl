#!/usr/bin/perl -w

use strict;

my ($expressed_exon_count,$exon_count,$sum_coverage,$mean_coverage);

while (<>){
  my @data=split("\t",$_);
  $exon_count++;

  if ($data[6]){
    if ($data[6]>0){
      $expressed_exon_count++;
    }

    $sum_coverage+=$data[6]
  }


}
$mean_coverage=$sum_coverage/$exon_count;

print "$exon_count total exons\n";
print "$expressed_exon_count expressed exons\n";
print "$mean_coverage average coverage\n";

exit;
