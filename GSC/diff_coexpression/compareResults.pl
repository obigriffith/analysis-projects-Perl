#!/usr/local/bin/perl -w

use strict;
use Data::Dumper;

my $results_dir = "/home/obig/Projects/diff_coexpression/results/prostate/Singh_prostate/n_comparisons/best_candidates/";

opendir(DIR, $results_dir) || die "can't opendir $results_dir: $!";
my @files = readdir(DIR);
closedir DIR;

my %PROBES;

#print Dumper (@files);

foreach my $file (@files){
  if ($file=~/\w+/){#don't include "." and ".." as files
#    print "$file\n";
    open (RESULTFILE, "$results_dir$file") or die "can't open $results_dir$file\n";
    while (<RESULTFILE>){
      my @entry = split (" ", $_);
      $PROBES{$entry[0]}++;
#      print "$entry[0]\t$entry[6]\n";
#      $MEAN_DIFFS{$file}{$entry[0]}=$entry[6];
    }
    close RESULTFILE;

  }
}

#Print numbers of times each probe was observed in the different files
foreach my $probe (sort keys %PROBES){
print "$probe\t$PROBES{$probe}\n";
}

#print Dumper (%PROBES);
