#!/usr/bin/perl -w

use strict;
use Data::Dumper;

my %Coexpression;
my %CoexpressionByClusterSize;
#For each cluster of genes we want to get corresponding coexpression

my $coexpression_data="/home/obig/Projects/clustering/coexpression_db/tmm/ensembl_mapped/coexpression.tmm_links_all_human_ENS30_35c.new.txt";
#my $coexpression_data="/projects/02/coexpression/processed_data/Updated_pearson_May13_ENS30/h_sapiens/human_Affy_gene_Pearson_MCE100.txt";
#my $coexpression_data="/projects/02/coexpression/processed_data/Updated_pearson_May13_ENS30/h_sapiens/human_SMD_cDNA_gene_Pearson_MCE100.txt";
#my $coexpression_data="/projects/02/coexpression/processed_data/Updated_pearson_May13_ENS30/h_sapiens/human_SAGE_gene_Pearson_MCE100.txt";

#my $gene_cluster_data="/home/obig/Projects/cisRED_coexpression/commonMotifAnalysis/CommonMotifGeneClusters_cisred_1_2a.clusters_only.txt";
#my $gene_cluster_data="/home/obig/Projects/cisRED_coexpression/commonMotifAnalysis/CommonMotifGeneClusters_random_cisred_1_2a.clusters_only100_20.txt";
my $gene_cluster_data="/home/obig/Projects/cisRED_coexpression/commonMotifAnalysis/CommonMotifGeneClusters_random_cisred_1_2a.clusters_only10000_20.txt";

my $max_group=20;

#Get unique gene list for motif/module clusters so that only necessary coexpression data is stored in hash (should reduce memory issues)
my %GENES;
open (GENECLUSTERS, $gene_cluster_data) or die "can't open $gene_cluster_data\n";
while (<GENECLUSTERS>){
  chomp;
  my @clusters = split("\t",$_);
  my @genes = split(" ", $clusters[1]);
  foreach my $gene (@genes){
    $GENES{$gene}++;
  }
}

#First load coexpression data
open (COEXPRESSION, $coexpression_data) or die "can't open $coexpression_data\n";
while (<COEXPRESSION>){
chomp;
my @genepair = split("\t",$_);
unless($GENES{$genepair[0]}){next;} #skip line if geneA not in genelist
unless($GENES{$genepair[1]}){next;} #skip line if geneB not in genelist
#print "$genepair[0] $genepair[1] $genepair[2]\n";
#$Coexpression{$genepair[0]}{$genepair[1]}=$genepair[2];
$Coexpression{$genepair[0]}{$genepair[1]}=abs($genepair[2]);
}
close COEXPRESSION;

#Now go through gene clusters and determine coexpression
open (GENECLUSTERS, $gene_cluster_data) or die "can't open $gene_cluster_data\n";
while (<GENECLUSTERS>){
  chomp;
  my @clusters = split("\t",$_);
  my $cluster_id=$clusters[0];
  my @genes = split(" ", $clusters[1]);
  my $gene_cluster_size=@genes;

  #Get coexpression for each gene pair in cluster
  my $coexpression_total=0;
  my $genepaircount=0;
  my ($i,$j);
  for ($i=0; $i<$gene_cluster_size; $i++){
    for ($j=0; $j<$gene_cluster_size; $j++){
      my $coexpression = 0;
      if ($i==$j){next;}#Skip self comparisons
      if ($Coexpression{$genes[$i]}{$genes[$j]}){ #Check for geneA geneB in coexpression data
	$coexpression=$Coexpression{$genes[$i]}{$genes[$j]};
      }elsif ($Coexpression{$genes[$j]}{$genes[$i]}){ #Otherwise check for geneB geneA
	$coexpression=$Coexpression{$genes[$j]}{$genes[$i]};
      }else{ #Otherwise set coexpression to zero
	$coexpression=0;
      }
      $genepaircount++;
      $coexpression_total+=$coexpression;
    }
  }
  my $coexpression_mean=$coexpression_total/$genepaircount;
#  print "$cluster_id\t$gene_cluster_size\t$coexpression_mean\t$clusters[1]\n";
  push (@{$CoexpressionByClusterSize{$gene_cluster_size}}, $coexpression_mean);
}
close GENECLUSTERS;

foreach my $gene_cluster_size(sort{$a<=>$b} keys %CoexpressionByClusterSize){
  if ($gene_cluster_size<$max_group){
    print "$gene_cluster_size\t",join("\t",@{$CoexpressionByClusterSize{$gene_cluster_size}}),"\n";
  }elsif($gene_cluster_size==$max_group){
    print "$max_group\t", join("\t",@{$CoexpressionByClusterSize{$gene_cluster_size}}),"\t";
  }else{
    print join("\t",@{$CoexpressionByClusterSize{$gene_cluster_size}}),"\t";
  }
}
print "\n";
#print Dumper (%CoexpressionByClusterSize);
exit;
