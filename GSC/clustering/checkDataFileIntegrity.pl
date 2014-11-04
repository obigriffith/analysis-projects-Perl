#!/usr/local/bin/perl -w

#This script will take a data file containing some delimited data matrix and check its integrity and dimensions
use strict;
use Getopt::Std;
use Data::Dumper;

getopts("f:");
use vars qw($opt_f);

my %summary;
my $file = $opt_f;
my $linecount=0;
my $datacount;

open (FILE, $file) or die "can't open $file\n";
while (<FILE>){
  my $line = $_;
  chomp $line;
  my @data = split (/\t/, $line, -1);
  $linecount++;
  $datacount = @data;
  $summary{$datacount}++;
  print "$linecount: $datacount\n";
#  print Dumper(@data);
#  exit;
}
close FILE;

foreach my $datacount (sort{$a<=>$b} keys %summary){
  print "$summary{$datacount} lines with $datacount datapoints\n";
}

exit;
