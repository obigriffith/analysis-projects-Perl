#!/usr/bin/perl -w

use strict;
use Data::Dumper;
use Getopt::Std;
getopts("c:m:a");
use vars qw($opt_c $opt_m $opt_a);

my %Coexpression;
my %CoexpressionByClusterSize;
#For each cluster of genes we want to get corresponding coexpression

my $coexpression_data = $opt_c; #File with gene pairs and corresponding coexpression score
my $gene_cluster_data = $opt_m; #File with clusters of genes based on motif/module cooccurence data
#my $max_group=$opt_n; Not used here

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
  if ($opt_a){ #Get absolute value if specified
    $Coexpression{$genepair[0]}{$genepair[1]}=abs($genepair[2]);
  }else{
    $Coexpression{$genepair[0]}{$genepair[1]}=$genepair[2];
  }
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
  my $genepaircount=0;
  my ($i,$j);
  my %genepairs=();
  for ($i=0; $i<$gene_cluster_size; $i++){
    for ($j=0; $j<$gene_cluster_size; $j++){
      my $coexpression = 0;
      if ($i==$j){next;}#Skip self comparisons
      if ($genepairs{$genes[$i]}{$genes[$j]} || $genepairs{$genes[$j]}{$genes[$i]}){next;} #skip geneb/genea if genea/geneb already observed
      if ($Coexpression{$genes[$i]}{$genes[$j]}){ #Check for geneA geneB in coexpression data
	$coexpression=$Coexpression{$genes[$i]}{$genes[$j]};
      }elsif ($Coexpression{$genes[$j]}{$genes[$i]}){ #Otherwise check for geneB geneA
	$coexpression=$Coexpression{$genes[$j]}{$genes[$i]};
      }else{ #Otherwise set coexpression to zero
	$coexpression=0;
      }
      $genepaircount++;
      $genepairs{$genes[$i]}{$genes[$j]}++; #take note of each gene pair processed so that it doesn't get included again
      push (@{$CoexpressionByClusterSize{$gene_cluster_size}}, $coexpression);
      #print "$cluster_id\t$genes[$i]\t$genes[$j]\t$coexpression\n";
      print "$gene_cluster_size\t$coexpression\t$cluster_id\t$genes[$i]\t$genes[$j]\n";
      #print "$gene_cluster_size\t$coexpression\n";
    }
  }
}
close GENECLUSTERS;


#foreach my $gene_cluster_size(sort{$a<=>$b} keys %CoexpressionByClusterSize){
#  if ($gene_cluster_size<=$max_group){
    #my $num_entries = @{$CoexpressionByClusterSize{$gene_cluster_size}};
#    print "$gene_cluster_size\t",join("\t",@{$CoexpressionByClusterSize{$gene_cluster_size}}),"\n";


#  }elsif($gene_cluster_size==$max_group){
#    print "$max_group\t", join("\t",@{$CoexpressionByClusterSize{$gene_cluster_size}}),"\t";
#  }else{
#    last;
#    print join("\t",@{$CoexpressionByClusterSize{$gene_cluster_size}}),"\t";
#  }
#}
#print "\n";

exit;
