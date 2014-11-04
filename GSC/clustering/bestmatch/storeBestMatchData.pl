#!/usr/bin/perl -w

use strict;
use Data::Dumper;
use Getopt::Std;
use Storable;

getopts("f:o:");
use vars qw($opt_f $opt_o);

#load all genes and their best matches for platform1 and platform2 results into hashes
#compare results of two methods by seeing how often they agree.

unless($opt_f){&printDocs();}

my $datafile = $opt_f;
my $outfile = $opt_o;
#my $platform1results = "sagetest.txt";
#my $platform2results = "microtest.txt";

my (@x, @y, @r);

#load platform1 results
print "\nLoading platform1 results\n";
open (PLATFORM1RESULTS, $datafile) or die "can't open $datafile\n";
my $arrayloadcount = 0;
while(<PLATFORM1RESULTS>) {
  if ($_=~/^(\S+)\s+(\S+)\s+(\S+)/){
    push(@x,$1); push(@y,$2); push(@r,$3);
    $arrayloadcount++;
    print "Results loaded into arrays: $arrayloadcount\r";
  }
}
my $x_ref = [@x];
my $y_ref = [@y];
my $r_ref = [@r];

#my $array = [$x_ref,$y_ref,$r_ref];
#my @arrays = [@x,@y,@r];
#my $arrays_ref = @arrays;
#my $arrays_ref = [@x,@y,@r];
my $arrays_ref = [$x_ref,$y_ref,$r_ref];

print "\n\nAttempting to store data using Storable function\n";

eval {
    store($arrays_ref, $outfile);
};
print "Error writing to file: $@" if $@;

exit;

sub printDocs{
  print "This script takes a tab-delimited files of the form 'gene1  gene2  value' and stores it using Storable\n";
  print "The following options are required:\n";
  print "-f infile\n";
  print "-o outputfile\n";
  print "Usage: storeBestMatchData.pl -f sagetest.txt -o sagetest_storable.txt\n";
  exit;
}
