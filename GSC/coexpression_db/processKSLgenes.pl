#!/usr/local/bin/perl -w

use strict;
my %genes;
my %ensg_hugo;
my %ensg_entrez;

while (<>){
  chomp $_;
  my @entry=split ("\t", $_);
  $genes{$entry[0]}++;
  if ($entry[1]){
    $ensg_hugo{$entry[0]}=$entry[1];
  }
  if ($entry[2]){
    $ensg_entrez{$entry[0]}=$entry[2];
  }
}

foreach my $gene(keys %genes){
  my ($hugo, $entrez);
  if ($ensg_hugo{$gene}){
    $hugo = $ensg_hugo{$gene};
  }else{$hugo="";}
  if ($ensg_entrez{$gene}){
    $entrez = $ensg_entrez{$gene};
  }else{$entrez="";}
  print "$gene\t$hugo\t$entrez\n";
#unless ($hugo){print "$gene\t$hugo\t$entrez\n";}
}
