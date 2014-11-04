#!/usr/bin/perl -w

use strict;
use Data::Dumper;
use Getopt::Std;

###This script generates an undefined number of gene clusters such that given the cluster size a certain number of total gene pairs results
getopts("f:m:n:");
use vars qw($opt_f $opt_m $opt_n);

srand(time() ^($$ + ($$ <<15))) ;

my $max_cluster_size = $opt_m; #Max gene cluster size
my $num_gene_pairs = $opt_n; #Total number of gene pairs desired (x).
my $num_clusters; #Number of random clusters to create for each geneclustersize

unless ($opt_f){print "usage: generateRandomGeneClusters2.pl -f genelistfile\n";exit;}

my $genelist = $opt_f;
my @genes;

open (GENELIST, $genelist) or die "can't open $genelist\n";
while (<GENELIST>){
chomp $_;
push (@genes, $_);
}
close GENELIST;

my $num_genes = @genes;

my ($m, $n, $g);
for ($m=2; $m<=$max_cluster_size; $m++){ #For each clustersize from 2 to max_cluster_size
  my $pairs_per_cluster=(($m*$m)-$m)/2; #For a clustersize of m what is the amount of pairs possible
  my $num_clusters=(int($num_gene_pairs/$pairs_per_cluster))+1; #Given the number of pairs per cluster of size m, how many clusters n do we need for a total of x pairs
  my $total_pairs = $num_clusters * $pairs_per_cluster;
  #print "Generating $num_clusters of size $m for a total of $total_pairs gene pairs\n";
  for ($n=1; $n<=$num_clusters; $n++){ #Get n clusters
    my @randcluster=();
    my %randclustergenes=();
    for ($g=1; $g<=$m; $g++){#get m genes

      my $rand_number = int(rand($num_genes));
      my $rand_gene = $genes[$rand_number];
      if ($randclustergenes{$rand_gene}){$g=$g-1;next;}#if gene has already been picked for this cluster, pick another one
      $randclustergenes{$rand_gene}++;
      push (@randcluster, $rand_gene);
    }
  print "randclust"."$m"."_"."$n\t",join(" ", @randcluster),"\n";
  }
}
