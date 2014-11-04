#!/usr/local/bin/perl -w

use strict;
use Getopt::Std;
getopts("f:n:");
use vars qw($opt_f $opt_n);

my $grand_total = 0;
my $linecount=0;
my $infile = $opt_f;
my $n = $opt_n;
my @total_tags;
for (my $i = 0; $i<=$n; $i++){  #first initialize all elements in array
$total_tags[$i]=0;
}

open (INFILE, $infile) or die "can't open $infile\n";
print "\ncounting tags\n";
my $headings_line = <INFILE>;
chomp $headings_line;
my @headings = split (/\t/, $headings_line);
while (<INFILE>){
  chomp $_;
  my @tags = split (/\t/,$_);
  for (my $i = 1; $i<=$n; $i++){
    my $tagcount = $tags[$i];
    unless ($tagcount=~/\d+/){$tagcount=0;} #deals with missing values
    $total_tags[$i]=$total_tags[$i]+$tagcount;
  }
  print "$linecount lines checked\r";
  $linecount++;
}

close INFILE;

my $max=0;
my $min=1000000000000000000; #some arbitrarily large value so that the first library size will have something to compare to.
for (my $i = 1; $i<=$n; $i++){
print "$headings[$i] has $total_tags[$i] total tags\n";
if ($total_tags[$i]>$max){$max=$total_tags[$i]}
if ($total_tags[$i]<$min){$min=$total_tags[$i]}
$grand_total = $grand_total + $total_tags[$i];
}

my $average = $grand_total/$n;
print "\n\n$grand_total Total Tags found\n";
print "$average is average library size\n";
print "$max is max library size\n";
print "$min is min library size\n";

exit;
