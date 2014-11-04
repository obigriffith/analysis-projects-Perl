#!/usr/bin/perl -w

use strict;

my $genepairlist = "/home/obig/clustering/coexpression_db/reliable_set/ensembl_mapped/complete_list_reliable.1.ENS22_34d.txt";
my %Pairs;
my $linecount = 0;
my $genepaircount=0;

open (GENEPAIRLIST, $genepairlist) or die "can't open $genepairlist\n";

while (<GENEPAIRLIST>){
  #First create a hash of hashes with all gene pairs
  if ($_=~/(\S+)\s+(\S+)\s+(\S+)/){
    my $gene1 = $1;
    my $gene2 = $2;
    my $pearson = $3;
    $Pairs{$gene1}{$gene2}=$pearson;
    $Pairs{$gene2}{$gene1}=$pearson;
    $linecount++;
  }
}


#Go through hash of gene pairs
foreach my $gene1 (sort keys %Pairs){
  my @sublist = ();
  foreach my $gene2 (sort keys %{$Pairs{$gene1}}){
    $genepaircount++;
    #print "$gene1\t$gene2\n";
    #collect all genes linked to gene1
    my $pearson = $Pairs{$gene1}{$gene2};
    my $value = "$gene2"." ($pearson)";
    push (@sublist, $value);
  }
  print "$gene1\t",join("; ",@sublist),"\n";
}
print "$linecount lines read\n";
print "$genepaircount gene pairs in hash\n";
