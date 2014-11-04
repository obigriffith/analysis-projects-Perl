#!/usr/bin/perl -w

use strict;
use Data::Dumper;

#Script not complete. Ended up answering question with command line.

my $dir="/csb/home/obig/Projects/BCCL/mutations";
my @files=`ls $dir`;
my %mutations;

foreach my $file (@files){
  chomp $file;
  print "$dir/$file\n";

  #parse cell line name
  if($file=~/(\w+)\_filt/){
    print "$1\n";
  }

  #open file
  open (FILE, $dir/$file) or die "can't open $file\n";
  while(<FILE>){
    @data=split("\t", $_)
    $mutation
  }

  close FILE;

}

#print Dumper(@files);


exit;

