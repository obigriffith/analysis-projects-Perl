#!/usr/bin/perl -w

use strict;
use Data::Dumper;

use Getopt::Std;
getopts("f:");
use vars qw($opt_f);

sub printDocs{
  print "usage: summarizeStanfordKiwiData.pl -f clusterfile
options:
-f Specify Stanford clusterfile to look for contamination by negative control sequences
";
  exit;
}

my $cluster_file=$opt_f;
my %NegSummary;
my %NegClusterCounts;
my %NegTotals;
my %ClusterCounts;
my %NegTotalsByClusterSize;
my %ClusterCountsByClusterSize;
my %NegClusterCountsByClusterSize;

chomp $cluster_file;
open (GENECLUSTERS, $cluster_file) or die "can't open $cluster_file\n";
while (<GENECLUSTERS>){
  chomp;
  my @data=split ("\t", $_);
  #Grab cluster id and number of dimensions off front of array
  my $cluster_id=shift(@data);
  my $num_dimensions=shift(@data);
  #Go through remaining genes and look for negative control probes.
  my $num_genes=@data;
  my $num_negs=0;
  foreach my $gene (@data){
    if ($gene=~/N\d+/){
      $num_negs++;
      #print "$cluster_id dimensions: $num_dimensions Found Negative control: $gene\n";
    }
  }
  print "$cluster_id\t$num_dimensions\t$num_genes\t$num_negs\n";
  $NegSummary{$cluster_id}{'num_dimensions'}=$num_dimensions;
  $NegSummary{$cluster_id}{'num_genes'}=$num_genes;
  $NegSummary{$cluster_id}{'num_negs'}=$num_negs;
}
close GENECLUSTERS;

foreach my $cluster (keys %NegSummary){
  my $num_dimensions=$NegSummary{$cluster}{'num_dimensions'};
  my $num_genes=$NegSummary{$cluster}{'num_genes'};
  my $num_negs=$NegSummary{$cluster}{'num_negs'};
  #Keep running totals of clusters, clusters with negatives, and total negatives for each number of genes/dimensions
  $NegTotals{$num_dimensions}{$num_genes}+=$num_negs;
  $ClusterCounts{$num_dimensions}{$num_genes}++;
  if ($num_negs>0){$NegClusterCounts{$num_dimensions}{$num_genes}++;}
  
  #Keep running totals of clusters, clusters with negatives, and total negatives for each number of genes
  $NegTotalsByClusterSize{$num_genes}+=$num_negs;
  $ClusterCountsByClusterSize{$num_genes}++;
  if ($num_negs>0){$NegClusterCountsByClusterSize{$num_genes}++;}
}


#print Dumper (%ClusterCounts);
#print Dumper (%NegTotals);
#print Dumper (%NegClusterCounts);

print "num_dimensions\tnum_genes\tcluster_count\tneg_cluster_count\tneg_gene_total\n";
foreach my $num_dimensions (sort{$a<=>$b} keys %ClusterCounts){
  foreach my $num_genes (sort{$a<=>$b} keys %{$ClusterCounts{$num_dimensions}}){
    my $negclustercount=0;
    my $negtotal=0;
    my $clustercount=$ClusterCounts{$num_dimensions}{$num_genes};
    if ($NegClusterCounts{$num_dimensions}{$num_genes}){
      $negclustercount=$NegClusterCounts{$num_dimensions}{$num_genes};
    }
    if ($NegTotals{$num_dimensions}{$num_genes}){
      $negtotal=$NegTotals{$num_dimensions}{$num_genes};
    }
    print "$num_dimensions\t$num_genes\t$clustercount\t$negclustercount\t$negtotal\n";
  }
}

print "\n\nnum_genes\tcluster_count\tneg_cluster_count\tneg_gene_total\n";
foreach my $num_genes (sort{$a<=>$b} keys %ClusterCountsByClusterSize){
  my $negclustercount=0;
  my $negtotal=0;
  my $clustercount=$ClusterCountsByClusterSize{$num_genes};
  if ($NegClusterCountsByClusterSize{$num_genes}){
    $negclustercount=$NegClusterCountsByClusterSize{$num_genes};
  }
  if ($NegTotalsByClusterSize{$num_genes}){
    $negtotal=$NegTotalsByClusterSize{$num_genes};
  }
  print "$num_genes\t$clustercount\t$negclustercount\t$negtotal\n";
}

