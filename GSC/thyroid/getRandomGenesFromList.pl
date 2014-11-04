#!/usr/local/bin/perl -w

use strict;
use Data::Dumper;
use Getopt::Std;

getopts("f:n:");
use vars qw($opt_f $opt_n);

unless($opt_f && $opt_n){print "you must specifiy a file and number of genes to get\nusage: getRandomGenesFromList.pl -f genelist.txt -n 100\n";exit;}

my @array;
my $genefile = $opt_f;
my $num_genes = $opt_n;

open (GENEFILE, $genefile) or die "can't open $genefile\n";
while (<GENEFILE>){
chomp;
push (@array, $_);
}
close GENEFILE;

my $arraysize=@array;
#print "finding $num_genes random genes from $arraysize total genes\n";

my $n = $num_genes;
my @rand_genes;
my $i;

for ($i=0; $i<$n; $i++){
  my $arraysize=@array; #each time through loop determine new array size
  my $rand_number = int(rand($arraysize)); #Generate a random integer from to use as array index
  #print "getting element from array of size $arraysize at $rand_number\n";
  push (@rand_genes,$array[$rand_number]); #Use random integer to grab an element from array
  splice (@array,$rand_number,1); #Now, remove element from array so that it can't be used again
}

foreach my $rand_gene (@rand_genes){
print "$rand_gene\n";
}

exit;
