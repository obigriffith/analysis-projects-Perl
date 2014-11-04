#!/usr/bin/perl -w

use strict;

#This script will filter a gene pair list down to those pairs which meet some threshold in a second gene pair list

my $file1 = "/home/sage/clustering/matrix/affy_micro_sage_comp/040407/results/for_GO/23sage_28micro_95affy/affy_gt95_common.txt";
#my $file2 = "/home/sage/clustering/matrix/affy_micro_sage_comp/040407/results/for_GO/23sage_28micro_95affy/micro_gt28_common.txt";
my $file2 = "/home/sage/clustering/matrix/affy_micro_sage_comp/040407/results/for_GO/23sage_28micro_95affy/sage_gt23_common.txt";
my %results1;
my $basename = "affy_w_sage_gt_";

print "loading file1\n";
open (FILE1, $file1) or die "can't open $file1\n";
while (<FILE1>){
  if ($_=~/(\d+\t\d+\t)(\S+)/){
    $results1{$1}=$2;
  }
}
close FILE1;

for (my $r=0; $r<=0.9; $r+=0.1){
  print "finding pairs in file1 for which r>$r in file2\n";
  my $outfile = "$basename"."$r".".txt";
  open (FILE2, $file2) or die "can't open $file2\n";
  open (OUTFILE, ">$outfile") or die "can't open $outfile\n";
  while(<FILE2>){
    if ($_=~/(\d+\t\d+\t)(\S+)/){
      my $pair = $1;
      my $pearson = $2;
      if ($2>$r){
	print OUTFILE "$pair"."$results1{$pair}\n"; #If the value for the pair from dataset2 meets the threshold, print the pair and value from dataset1
      }
    }
  }
  close OUTFILE;
  close FILE2;
}

exit;
