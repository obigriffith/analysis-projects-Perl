#!/usr/bin/perl -w

use strict;

my %counts;

while (<>){
my @entry = split ("\t", $_);
my @genes = split (" ", $entry[1]);
my $genecount = @genes;
#print "$entry[0]\t$genecount\n";
$counts{$genecount}++;
}

foreach my $count (sort{$a<=>$b} keys %counts){
print "$count\t$counts{$count}\n";
}

