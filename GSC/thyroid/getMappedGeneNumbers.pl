#!/usr/local/bin/perl -w
use strict;

#my $comp_details = "/home/obig/Projects/thyroid/analysis/summary8/Thyroid_literature_data_summary8_mapped_all_comps.txt";
#my $comp_details = "/home/obig/Projects/thyroid/analysis/summary8/Thyroid_literature_data_summary8_mapped_comp12.txt";
my $comp_details = "/home/obig/Projects/thyroid/analysis/Affy_Meta/Thyroid_Affy_metaanalysis_summary_mapped_cancer_vs_noncancer.txt";

open (COMPDETAILS, $comp_details) or die "can't open $comp_details\n";

my %comp_summary;

my $firstline = <COMPDETAILS>;
while (<COMPDETAILS>){
chomp;
my @entry = split ("\t", $_);
my $comparison = $entry[1];
my $entrez_id = $entry[3];
my $up_down = $entry[22];
$comp_summary{$comparison}{$up_down}{$entrez_id}++;
}

foreach my $comparison (sort{$a<=>$b} keys %comp_summary){
  foreach my $up_down (sort{$b cmp $a} keys %{$comp_summary{$comparison}}){
    my $gene_count=0;
    foreach my $entrez_id (sort keys %{$comp_summary{$comparison}{$up_down}}){
      $gene_count++;
    }
    print "$comparison\t$up_down\t$gene_count\n";
  }
}

exit;
