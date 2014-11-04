#!/usr/local/bin/perl -w

use strict;

my $hour0file = "/home/obig/Projects/leukemia/tm1_11_microarray/processed_data/h10_to_h20/h13_h15_h17_summary_stats.txt";
my $hour48file = "/home/obig/Projects/leukemia/tm1_11_microarray/processed_data/h10_to_h20/h14_h16_h18_summary_stats.txt";

my ($hour0_probe,$hour48_probe,$hour0_mean_int,$hour48_mean_int,$hour0_var,$hour48_var,$hour0_mean_pval,$hour48_mean_pval);

open (HOUR0, $hour0file);
my $firstline = <HOUR0>;
while (<HOUR0>){
  if ($_=~/(\S+)\s+(\S+)\s+(\S+)\s+(\S+)/){
    $hour0_probe = $1;
    $hour0_mean_int = $2;
    $hour0_var = $3;
    $hour0_mean_pval = $4;
    open (HOUR48, $hour48file) or die "can't open $hour48file\n";
    while (<HOUR48>){
      if ($_=~/(\S+)\s+(\S+)\s+(\S+)\s+(\S+)/){
	$hour48_probe = $1;
	$hour48_mean_int = $2;
	$hour48_var = $3;
	$hour48_mean_pval = $4;
	#print "Comparing $hour48_probe to $hour0_probe\n";
	if ($hour48_probe eq $hour0_probe){
	  #print "$hour0_probe\t$hour0_mean_int\t$hour48_mean_int\t$hour0_var\t$hour48_var\t$hour0_mean_pval\t$hour48_mean_pval\n";
	  my $combined_mean = ($hour0_mean_int + $hour48_mean_int)/2;
	  my $combined_var = ($hour0_var + $hour48_var)/2;
	  my $combined_mean_pvalue = ($hour0_mean_pval + $hour48_mean_pval)/2;
	  print "$hour0_probe\t$combined_mean\t$combined_var\t$combined_mean_pvalue\n";
	  last;
	}
      }
    }
    close HOUR48;
  }
}
close HOUR0;
