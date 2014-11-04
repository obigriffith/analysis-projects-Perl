#!/usr/local/bin/perl -w

use strict;

use Data::Dumper;
use Getopt::Std;

getopts("f:");
use vars qw($opt_f);

my $infile = $opt_f;
my %genes;
my %genepairs;

open (INFILE, $infile) or die "can't open $infile\n";
while (<INFILE>){
  if ($_=~/(\S+)\s+(\S+)/){
    $genes{$1}++;
    $genes{$2}++;
  }
}

close INFILE;

#print Dumper(%genes);
foreach my $gene (sort {$genes{$a}<=>$genes{$b}}(keys %genes)){
  $genepairs{$genes{$gene}}++;
  print "$gene\t$genes{$gene}\n";
}

#print Dumper(%genepairs);
foreach my $genepair_number (sort{$a<=>$b} keys %genepairs){
#  print "$genepair_number\t$genepairs{$genepair_number}\n";
}

exit;
