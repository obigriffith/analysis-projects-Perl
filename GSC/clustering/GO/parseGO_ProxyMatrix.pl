#!/usr/bin/perl -w

use strict;
use Data::Dumper;
use Getopt::Std;
getopts("f:");
use vars qw($opt_f);
my $infile = $opt_f;

my $gene_count=0;
my @data;
my @genelist;

open (INFILE, $infile) or die "can't open $infile\n";

my $gene_number = <INFILE>; chomp $gene_number; #first file lists numbers of genes
my $gene;
while (<INFILE>){
  my $line=$_;
  if ($line=~/^(\S+)\n/){
#    print "gene found:$1\n";
    $gene=$1;
    $gene_count++;
    $genelist[$gene_count]=$gene;
#    $gene_found=1;
    next;
  }else{
    #if ($gene_found==1){
    $data[$gene_count]="$gene"." "."$line";
    #$gene_found=0;
    next;
  }
}

print "$gene_count of $gene_number expected genes found\n";
my $i;

for ($i=1; $i<=$gene_count; $i++){
  print "\t$genelist[$i]";
}
print "\n";

for ($i=1; $i<=$gene_count; $i++){
  print "$data[$i]";
}


