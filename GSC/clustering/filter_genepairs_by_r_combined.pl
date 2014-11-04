#!/usr/bin/perl -w

use strict;
use Getopt::Std;
getopts("a:b:m:o:t:c");
use vars qw($opt_a $opt_b $opt_m $opt_o $opt_t $opt_c);

#This script will filter a gene pair list down to those pairs which meet some combined pearson threshold in two datasets

unless ($opt_a && $opt_b && $opt_o){&printDocs();}
my $file1 = $opt_a;
my $file2 = $opt_b;
my $min_threshold = $opt_m || 0; #does this syntax work?
my $combined_threshold = $opt_t || 0;
my $outfile = $opt_o;
my %data1;

print "will identify gene pairs with a min threshold of r > $min_threshold and a combined threshold of r_comb > $combined_threshold\n";

open (OUTFILE, ">$outfile") or die "can't open $outfile\n";

#Load data from first file into hash
print "loading file1\n";
open (FILE1, $file1) or die "can't open $file1\n";
while (<FILE1>){
  if ($_=~/(\S+)\t(\S+)\t(\S+)/){
    if ($3>=$min_threshold){  #requires some minimum for pearson value before even considering combined score. Should help with memory issues
      $data1{$1}{$2}=$3;
    }
  }
}
close FILE1;

#load data from 2nd file and check combined score with data from file1 against threshold if present
print "loading file2\n";
open (FILE2, $file2) or die "can't open $file2\n";
while(<FILE2>){
  if ($_=~/(\S+)\t(\S+)\t(\S+)/){
    my $gene1 = $1;
    my $gene2 = $2;
    my $pearson2 = $3;
    unless ($pearson2>=$min_threshold){next;}#apply minimum criteria again
    #If pair was also present in file1 check combined score
    my $pearson1;
    if ($data1{$gene1}{$gene2}){
      $pearson1=$data1{$gene1}{$gene2};
    }elsif ($data1{$gene2}{$gene1}){#check for gene pair in either order
      $pearson1=$data1{$gene2}{$gene1};
    }else{
      next; #if not found in either orientation skip to next pair
    }

    #Combine pearson1 and pearson2 and check against threshold
    my $combined_pearson = $pearson1 + $pearson2;
    if ($combined_pearson>=$combined_threshold){
      if ($opt_c){
	print OUTFILE "$gene1\t$gene2\t$combined_pearson\n";
      }else{
	print OUTFILE "$gene1\t$gene2\t$pearson1\t$pearson2\n";
      }
    }
  }
}
close OUTFILE;
exit;

sub printDocs{
print "This script takes 2 files of the form \"gene1 gene2 value\" and determines which pairs meet a defined individual threshold and/or combined threshold
options:
-a file1
-b file2
-o outputfile
-m minimum threshold
-t combined threshold
-c print combined pearson instead of individual pearsons
usage: filter_genepairs_by_r_combined.pl -a affy -b cDNA -o affy_cDNA_1.2.txt -m 0 -t 1.2\n";
exit;
}
