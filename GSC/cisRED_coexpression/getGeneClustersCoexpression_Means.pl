#!/usr/bin/perl -w

use strict;
use Data::Dumper;
use Getopt::Std;
getopts("f:");
use vars qw($opt_f);

#Provide input file of format "module_gene_count\tcoexp_score\tmodule_name\tgeneA\tgeneB\n";
my $modulecoexpressionfile = $opt_f;
my %geneclusters;
my %clustersizes;

#Read all gene pairs coexpression data for each module
open (MOD_COEXP, $modulecoexpressionfile) or die "can't open $modulecoexpressionfile\n";
while (<MOD_COEXP>){
chomp;
my @entry = split("\t", $_);
my $cluster_size=$entry[0];
my $coexp_score=$entry[1];
my $module=$entry[2];
my $geneA=$entry[3];
my $geneB=$entry[4];
$clustersizes{$module}=$cluster_size;
$geneclusters{$module}{$geneA}{$geneB}=$coexp_score;
}

#For each module, determine mean coexpression and number of non-zero gene pairs
foreach my $module (sort keys %geneclusters){
  my %modulegenes;
  my $total_coexp=0;
  my $coexp_count=0;
  my $non_zero_genes=0;
  foreach my $geneA (sort keys %{$geneclusters{$module}}){
    $modulegenes{$geneA}++;
    foreach my $geneB (sort keys %{$geneclusters{$module}{$geneA}}){
      $modulegenes{$geneB}++;
      my $coexp_score=$geneclusters{$module}{$geneA}{$geneB};
      $total_coexp+=$coexp_score;
      $coexp_count+=1;
      unless($coexp_score==0){$non_zero_genes++;}
    }
  }
  my $mean_coexp = $total_coexp/$coexp_count;
  my @modulegenes= keys(%modulegenes);
  my $clustersize=$clustersizes{$module};
  my $max_gene_pairs = (($clustersize**2)-$clustersize)/2;

  print "$clustersize\t$max_gene_pairs\t$non_zero_genes\t$mean_coexp\t$module\t", join(" ", @modulegenes),"\n";
}
close MOD_COEXP;
exit;
