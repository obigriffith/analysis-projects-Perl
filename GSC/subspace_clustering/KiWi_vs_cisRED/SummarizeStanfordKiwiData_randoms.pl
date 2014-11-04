#!/usr/bin/perl -w

use strict;
use Data::Dumper;

use Getopt::Std;
getopts("f:d:o:");
use vars qw($opt_f $opt_d $opt_o);

unless ($opt_f && $opt_d){
&printDocs();
exit;
}

sub printDocs{
print "usage: summarizeStanfordKiwiData.pl -f clusterfile -d randomclusterfilesdir -o outputfile
options:
-f Specify Stanford clusterfile to look for contamination by negative control sequences
-d Specify directory with multiple random clusterfiles to summarize
-o specify output file
";
exit;
}

if ($opt_o){
open (OUTFILE, ">$opt_o") or die "can't open $opt_o\n";
}

my @cluster_files;
my $gene_cluster_file=$opt_f;
my %NegSummary;
my %RandNegSummary;
my %ClusterSizes;

my $cluster_file=$opt_f;
my @rand_cluster_files=`ls $opt_d`;
my @cluster_file_dimensions; #Store dimensions from actual clusters and use these for random clusters

###Go through actual data first###
open (GENECLUSTERS, $cluster_file) or die "can't open $cluster_file\n";
while (<GENECLUSTERS>){
  chomp;
  my @data=split ("\t", $_);
  #Grab cluster id and number of dimensions off front of array
  my $cluster_id=shift(@data);
  my $num_dimensions=shift(@data);
  push (@cluster_file_dimensions, $num_dimensions);
  #Go through remaining genes and look for negative control probes.
  my $num_genes=@data;
  $ClusterSizes{$num_genes}++; #Keep track of all possible clustersizes
  my $num_negs=0;
  foreach my $gene (@data){
    if ($gene=~/N\d+/){
      $num_negs++;
      #print "$cluster_id dimensions: $num_dimensions Found Negative control: $gene\n";
    }
  }
  #print "$cluster_id\t$num_dimensions\t$num_genes\t$num_negs\n";
  $NegSummary{$cluster_id}{'num_dimensions'}=$num_dimensions;
  $NegSummary{$cluster_id}{'num_genes'}=$num_genes;
  $NegSummary{$cluster_id}{'num_negs'}=$num_negs;
}
close GENECLUSTERS;

my @clustersizes = sort{$a<=>$b} keys %ClusterSizes;
if ($opt_o){print OUTFILE join("\t",@clustersizes),"\n";}
#print join("\t",@clustersizes),"\n";

###Then, go through each random cluster file###
foreach my $rand_cluster_file (@rand_cluster_files){
  my @cluster_file_dims=@cluster_file_dimensions; #For each set of random clusters use the same dimension numbers as for the non-random clusters
  chomp $rand_cluster_file;
  print "processing $rand_cluster_file\n";
  $rand_cluster_file="$opt_d/"."$rand_cluster_file";
  open (RANDGENECLUSTERS, $rand_cluster_file) or die "can't open $rand_cluster_file\n";
  while (<RANDGENECLUSTERS>){
    chomp;
    my @data=split ("\t", $_);
    #Grab cluster id and number of dimensions off front of array
    my $cluster_id=shift(@data);
    my $num_dimensions=shift(@cluster_file_dims);
    #Go through remaining genes and look for negative control probes.
    my $num_genes=@data;
    my $num_negs=0;
    foreach my $gene (@data){
      if ($gene=~/N\d+/){
	$num_negs++;
	#print "$cluster_id dimensions: $num_dimensions Found Negative control: $gene\n";
      }
    }
    #print "$cluster_id\t$num_dimensions\t$num_genes\t$num_negs\n";
    $RandNegSummary{$cluster_id}{'num_dimensions'}=$num_dimensions;
    $RandNegSummary{$cluster_id}{'num_genes'}=$num_genes;
    $RandNegSummary{$cluster_id}{'num_negs'}=$num_negs;
  }
  close RANDGENECLUSTERS;

  #Go through each cluster and summarize
  my %NegClusterCounts;
  my %NegTotals;
  my %ClusterCounts;
  my %NegTotalsByClusterSize;
  my %ClusterCountsByClusterSize;
  my %NegClusterCountsByClusterSize;
  foreach my $cluster (sort keys %RandNegSummary){
    my $num_dimensions=$RandNegSummary{$cluster}{'num_dimensions'};
    my $num_genes=$RandNegSummary{$cluster}{'num_genes'};
    my $num_negs=$RandNegSummary{$cluster}{'num_negs'};
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

  ###Summarize data by both number of genes and number of dimensions.
  #print "num_dimensions\tnum_genes\tcluster_count\tneg_cluster_count\tneg_gene_total\n";
  #foreach my $num_dimensions (sort{$a<=>$b} keys %ClusterCounts){
  #foreach my $num_genes (sort{$a<=>$b} keys %{$ClusterCounts{$num_dimensions}}){
  #my $negclustercount=0;
  #my $negtotal=0;
  #my $clustercount=$ClusterCounts{$num_dimensions}{$num_genes};
  #if ($NegClusterCounts{$num_dimensions}{$num_genes}){
  #$negclustercount=$NegClusterCounts{$num_dimensions}{$num_genes};
  #}
  #if ($NegTotals{$num_dimensions}{$num_genes}){
  #$negtotal=$NegTotals{$num_dimensions}{$num_genes};
  #}
  #print "$num_dimensions\t$num_genes\t$clustercount\t$negclustercount\t$negtotal\n";
  #}
  #}

  ###Sumarize by number of genes
  #print "\n\nnum_genes\tcluster_count\tneg_cluster_count\tneg_gene_total\n";

  my @mean_fractions;
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
    #print "$num_genes\t$clustercount\t$negclustercount\t$negtotal\n";
    my $mean_fraction_neg_genes=$negtotal/($num_genes*$clustercount); #total negative genes divided by total genes gives fraction/percent negative contamination for each cluster size
    push (@mean_fractions, $mean_fraction_neg_genes);
  }
  if ($opt_o){print OUTFILE join ("\t", @mean_fractions), "\n";}
  #print join ("\t", @mean_fractions), "\n";
}

if ($opt_o){close OUTFILE;}
