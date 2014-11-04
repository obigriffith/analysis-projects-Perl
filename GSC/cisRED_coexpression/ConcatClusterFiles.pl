#!/usr/bin/perl -w

use strict;
use Data::Dumper;
use Getopt::Std;
getopts("d:");
use vars qw($opt_d);

#This script takes in a directory of files with one cluster of genes per file (one gene per line)
#It writes the contents to a new file with each cluster of genes on a single line (tab-delimeted)

my $dir = $opt_d;

my @files = `ls $dir`;
#print Dumper (@files);

foreach my $file (@files){
  chomp $file;
  my $filepath = "$dir/$file";
  open (FILE, $filepath) or die "can't open $filepath\n";
  my %genes;
  while (<FILE>){
    if ($_=~/(ENSG\w+)/){
      $genes{$1}++;
    }
  }
  my $genecount = keys %genes;
  if ($genecount>1){
    my @cluster;
    foreach my $gene (keys %genes){
      push (@cluster, $gene);
    }
    print "$file\t", join(" ", @cluster), "\n";
  }
close FILE;
}
