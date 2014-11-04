#!/usr/bin/perl -w

use strict;
use Data::Dumper;
my $drug_record_file="/home/obig/Projects/Iressa_Breast_Cancer/drugs/drugcard_set.txt";
#my $gene_summary_file="Gene_level/iressa_ht3_AC_BF_2fold_up_Drugs.txt";
#my $gene_summary_file="Transcript_level/iressa_ht1_AC_BF_2fold_up_Drugs.txt";
#my $gene_summary_file="Specific_Transcript_level/iressa_ht2_AC_BF_2fold_up_Drugs.txt";

#my $gene_summary_file="/home/obig/Projects/Iressa_Breast_Cancer/drugs/blast/SUM149/GeneResults_SUM149.drugs.txt";
#my $gene_summary_file="/home/obig/Projects/Iressa_Breast_Cancer/drugs/blast/A431/GeneResults_A431.drugs.txt";
#my $gene_summary_file="/home/obig/Projects/Iressa_Breast_Cancer/drugs/blast/A431_SUM149/GeneResults_A431_SUM149_overlap.drugs.txt";

#my $gene_summary_file="/home/obig/Projects/Iressa_Breast_Cancer/drugs/blast/SUM149/GeneResults_SUM149.UP.drugs.txt";
#my $gene_summary_file="/home/obig/Projects/Iressa_Breast_Cancer/drugs/blast/A431/GeneResults_A431.UP.drugs.txt";
my $gene_summary_file="/home/obig/Projects/Iressa_Breast_Cancer/drugs/blast/A431_SUM149/GeneResults_A431_SUM149_overlap.UP_cons.drugs.txt";



my %drugs;

open (DRUGRECORDS, $drug_record_file) or die "can't open $drug_record_file\n";
#Set input separator for each drugcard record
$/="BEGIN_DRUGCARD";
my $empty=<DRUGRECORDS>;
while(<DRUGRECORDS>){
  my $record=$_;
  #print Dumper ($record);
  my ($record_id, $generic_name);
  my $synonyms="NA";
  my $brand_names="NA";
  my $drug_type="NA";
  my $drug_category="NA";
  my $mol_weight="NA";
  my $exp_water_sol="NA";
  my $drug_target_count=0;
  if ($record=~/Primary_Accession_No\:\n(\w+\d+)/g){$record_id=$1;}
  if ($record=~/Generic_Name\:\n(.+)\n/g){$generic_name=$1;}
  if ($record=~/Synonyms\:\n(.+)\n/g){$synonyms=$1;}
  if ($record=~/Brand_Names\:\n(.+)\n/g){$brand_names=$1;}
  if ($record=~/Drug_Type\:\n(.+)\n/g){$drug_type=$1;}
  if ($record=~/Drug_Category\:\n(.+)\n/g){$drug_category=$1;}
  while ($record=~/(Drug_Target_\d+_ID\:)/g){$drug_target_count++;}
  #if ($record=~/Experimental_Water_Solubility/g){print "found it\n";exit;}
  if ($record=~/\#\sMolecular_Weight_Avg\:\n(.+)\n/g){$mol_weight=$1;}
  if ($record=~/\#\sExperimental_Water_Solubility\:\n(.+)\n/g){$exp_water_sol=$1;}

  $drugs{$record_id}{'generic_name'}=$generic_name;
  $drugs{$record_id}{'synonyms'}=$synonyms;
  $drugs{$record_id}{'brand_names'}=$brand_names;
  $drugs{$record_id}{'drug_type'}=$drug_type;
  $drugs{$record_id}{'drug_category'}=$drug_category;
  $drugs{$record_id}{'avg_mol_weight'}=$mol_weight;
  $drugs{$record_id}{'exp_water_sol'}=$exp_water_sol;
  $drugs{$record_id}{'drug_target_count'}=$drug_target_count;


#  print "$record_id\t$generic_name\t$synonyms\t$brand_names\t$drug_type\t$drug_category\n";
}
#Reset file input separator
$/="\n";

#Go through genes probes. For those with uniprot_id and one or more drugs, collect details from drug records
print "gene_id\tuniprot_id\tdrug_id\tgeneric_name\tdrug_type\tdrug_category\tavg_mol_weight(g/mol)\texp_water_sol\tdrug_target_count\tbrand_names\n";
open (GENESUMMARY, $gene_summary_file) or die "can't open $gene_summary_file\n";
my $header=<GENESUMMARY>;
while (<GENESUMMARY>){
  my $data=$_;
  chomp $data;
  my @data=split("\t", $data);
  my $gene=$data[0];
  my $uniprot_id=$data[1];
  my $drugs=$data[2];
  unless ($uniprot_id eq "NA" || $drugs eq "NA"){
    my @drugs=split(";", $drugs);
    foreach my $drug(@drugs){
      print "$gene\t$uniprot_id\t$drug\t$drugs{$drug}{'generic_name'}\t$drugs{$drug}{'drug_type'}\t$drugs{$drug}{'drug_category'}\t$drugs{$drug}{'avg_mol_weight'}\t$drugs{$drug}{'exp_water_sol'}\t$drugs{$drug}{'drug_target_count'}\t$drugs{$drug}{'brand_names'}\n";
    }
  }

}
close GENESUMMARY;
