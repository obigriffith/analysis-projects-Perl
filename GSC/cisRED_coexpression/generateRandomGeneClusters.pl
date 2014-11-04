#!/usr/bin/perl -w

use strict;
use Data::Dumper;

srand(time() ^($$ + ($$ <<15))) ;

my $max_cluster_size = 20; #Max gene cluster size
my $num_clusters = 10000; #Number of random clusters to create for each geneclustersize
#my $genelist="/home/obig/Projects/clustering/coexpression_db/tmm/ensembl_mapped/TMM_ENS30_35c.new.uniq"; #file containing list of genes from which to create random clusters
my $genelist="/home/obig/Projects/cisRED_coexpression/cisred_1_2a_ENSG_IDs";
my @genes;

###Should we use all genes in coexpression data or all genes in cisRED?

open (GENELIST, $genelist) or die "can't open $genelist\n";
while (<GENELIST>){
chomp $_;
push (@genes, $_);
}
close GENELIST;

my $num_genes = @genes;

my ($m, $n, $g);
for ($m=2; $m<=$max_cluster_size; $m++){ #For each clustersize from 2 to max_cluster_size
  for ($n=1; $n<=$num_clusters; $n++){ #Get n clusters
    my @randcluster=();
    for ($g=1; $g<=$m; $g++){#get m genes
      my $rand_number = int(rand($num_genes));
      my $rand_gene = $genes[$rand_number];
      push (@randcluster, $rand_gene);
    }
  print "randclust"."$m"."_"."$n\t",join(" ", @randcluster),"\n";
  }
}
