#!/usr/bin/perl -w

use strict;
use Data::Dumper;

my $drug_mapping="/home/obig/Projects/Iressa_Breast_Cancer/drugs/drugcard_drugtarget_swissprot_ids.txt";
#my $uniprot_mapping="/home/obig/Projects/Iressa_Breast_Cancer/drugs/exonerate/Gene_level/iressa_ht3_AC_BF_2fold_up_ENSG2Uniprot.txt";
#my $uniprot_mapping="/home/obig/Projects/Iressa_Breast_Cancer/drugs/exonerate/Transcript_level/iressa_ht1_AC_BF_2fold_up_ENST2Uniprot.txt";
#my $uniprot_mapping="/home/obig/Projects/Iressa_Breast_Cancer/drugs/exonerate/Specific_Transcript_level/Iressa_ht2_AC_BF_2fold_up_specific_ENST2Uniprot.txt";
#my $uniprot_mapping="/home/obig/Projects/Iressa_Breast_Cancer/drugs/blast/A431_SUM149/GeneResults_A431_SUM149_overlap.ENSG2Uniprot.txt";
#my $uniprot_mapping="/home/obig/Projects/Iressa_Breast_Cancer/drugs/blast/A431/GeneResults_A431.ENSG2Uniprot.txt";
#my $uniprot_mapping="/home/obig/Projects/Iressa_Breast_Cancer/drugs/blast/SUM149/GeneResults_SUM149.ENSG2Uniprot.txt";

#my $uniprot_mapping="/home/obig/Projects/Iressa_Breast_Cancer/drugs/blast/SUM149/GeneResults_SUM149.UP.ENSG2Uniprot.txt";
#my $uniprot_mapping="/home/obig/Projects/Iressa_Breast_Cancer/drugs/blast/A431/GeneResults_A431.UP.ENSG2Uniprot.txt";
my $uniprot_mapping="/home/obig/Projects/Iressa_Breast_Cancer/drugs/blast/A431_SUM149/GeneResults_A431_SUM149_overlap.UP_cons.ENSG2Uniprot.txt";


#Read in uniprot mappings
my %gene2uni;
open (UNIPROT, $uniprot_mapping) or die "can't open $uniprot_mapping\n";
my $uniprot_header=<UNIPROT>;
chomp $uniprot_header;
while(<UNIPROT>){
  my $data=$_;
  chomp $data;
  if ($data=~/^(\S+)\t(\w+)/){
    $gene2uni{$1}=$2;
  }
}
close UNIPROT;

#Read in uniprot to drug mappings
my %drugs;
open (DRUGS, $drug_mapping) or die "can't open $drug_mapping\n";
while(<DRUGS>){
  my $data=$_;
  chomp $data;
  if ($data=~/^(\w+)\t(\w+)/){
    $drugs{$2}{$1}++;
  }
}
close DRUGS;

#Now, go through all significant genes and combine with other data
foreach my $gene (sort keys %gene2uni){
  my $uniprot_id = $gene2uni{$gene};

  my $drugs;
  if ($uniprot_id eq "NA"){
    $drugs="NA";
  }else{
    if ($drugs{$uniprot_id}){
      my @drugs;
      foreach my $drug (sort keys %{$drugs{$uniprot_id}}){
	push (@drugs, $drug);
      }
      $drugs=join(";",@drugs);
    }else{
      $drugs="NA";
    }
  }
  print "$gene\t$uniprot_id\t$drugs\n";

}
