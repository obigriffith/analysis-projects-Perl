#!/usr/local/bin/perl -w

use strict;

my %COEX;

#Takes Oncomine output and summarizes results for each gene


while (<>){
  if ($_=~/(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)/){
    my $experiment = $1;
    my $probe = $2;
    my $coexpressed_probe = $3;
    my $probe_pair = "$probe"."_"."$coexpressed_probe";
    my $experiment_id = $4;
    my $gene = $5;
    my $coexpressed_gene = $6;
    my $r = $7;
    $COEX{$gene}{$coexpressed_gene}{$experiment}{$probe_pair}=$r;
  }
}


print "gene\tcoex_gene\texp_count\tprobe_pair_count\tr_avg\n";
foreach my $gene (sort keys %COEX){
  foreach my $coexpressed_gene (sort keys %{$COEX{$gene}}){
    my $exp_count = 0;
    my $evidence_count = 0;
    my $r_sum;
    foreach my $experiment (sort keys %{$COEX{$gene}{$coexpressed_gene}}){
      $exp_count++;
      foreach my $probe_pair (sort keys %{$COEX{$gene}{$coexpressed_gene}{$experiment}}){
	$evidence_count++;
	$r_sum += $COEX{$gene}{$coexpressed_gene}{$experiment}{$probe_pair};
	#print "$coexpressed_gene\n";
      }
    }
    my $r_avg = $r_sum/$evidence_count;
    print "$gene\t$coexpressed_gene\t$exp_count\t$evidence_count\t$r_avg\n";
  }
}
exit;
