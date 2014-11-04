#!/usr/local/bin/perl -w

use strict;
use Data::Dumper;

my $xrefs_file="/home/obig/Projects/sub_space_clustering/GO_analysis/human.xrefs_20060121";
my $genelist_file="/home/obig/Projects/sub_space_clustering/GO_analysis/gene_association.goa_human_2006_01_26.genelist";
my %xrefs;
my %mapped;

#Load xrefs info into hash
open (XREFS, $xrefs_file) or die "can't open $xrefs_file\n";
my $header=<XREFS>;#skip first line
while (<XREFS>){
  my @entries = split("\t",$_,-1);
  my $source_db=$entries[0]; #Database from which master entry of this IPI entry has been taken. One of either SP (UniProt/Swiss-Prot), TR (UniProt/TrEMBL), ENSEMBL (Ensembl), REFSEQN (RefSeq NP data set), REFSEQX (Refseq XP data set), TAIR (TAIR Protein data set) or HINV (H-Invitational Database).
  my $protein_id=$entries[1]; #UniProt accession number or Ensembl ID or RefSeq ID or TAIR Protein ID or HINV (H-Invitational Database).
  my $IPI_id=$entries[2]; #International Protein Index identifier
  my $ENSP_id=$entries[5]; #Supplementary Ensembl entries associated with this IPI entry.

  $xrefs{$protein_id}{'source_db'}=$source_db;
  $xrefs{$protein_id}{'IPI_id'}=$IPI_id;
  $xrefs{$protein_id}{'ENSP_id'}=$ENSP_id;
}
close XREFS;

#Now, go through genelist and map id from xrefs file.
open (GENELIST, $genelist_file) or die "can't open $genelist_file\n";
while (<GENELIST>){
  my $gene=$_;
  chomp $gene;
  if ($gene=~/^ENSP\w+/){ #If ID is already and ENSP id - then just use as is.
    $mapped{$gene}=$gene;
    next;
  }
  if ($xrefs{$gene}){#Check to see if gene is in xrefs file
    $mapped{$gene}=$xrefs{$gene}{'ENSP_id'};
  }
}

foreach my $gene (sort keys %mapped){
  if ($mapped{$gene}=~/^(ENSP\w+)\;/){
    print "$gene\t$1\n";
  }
}
