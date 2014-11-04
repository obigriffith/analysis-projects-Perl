#!/usr/bin/perl -w

use strict;
use Data::Dumper;
use Getopt::Std;
getopts("t:c:a:");
use vars qw($opt_t $opt_c $opt_a);

my @explist;
my %clusters;
my %terms;
my %annotations;
my $min_inclust_interm=1;

unless($opt_t && $opt_c && $opt_a){
  print "you must supply a total experiment list, cluster file, and experiment annotation file.  Usage:\nprepareFisherExact.pl -t totalexplist.txt -c clusterfile.txt -a annotation_file.txt\n";
  exit;
}

my $total_exp_list=$opt_t; # eg. /home/obig/Projects/sub_space_clustering/expO/normalized/GSE2109_gcrma_explist.txt
#my $subspace_exp_clusters="/home/obig/Projects/sub_space_clustering/KiWi/GSE2109/k100000_w18_subs1_kplus100000/cluster_files/GSE2109_gcrma_mapped_mincluster5_mindim15_w_clustername_exps.txt";
my $subspace_exp_clusters=$opt_c; # eg. /home/obig/Projects/sub_space_clustering/KiWi/GSE2109/k100000_w18_subs1_kplus100000/random_cluster_files/GSE2109_gcrma_mapped_mincluster5_mindim15_w_clustername_exps.random.1.txt
my $exp_annotation_info=$opt_a; # eg. /home/obig/Projects/sub_space_clustering/expO/GSE2109_16Aug2006_sample_details.clean.txt


#Load total experiment list
open (EXPLIST, $total_exp_list) or die "can't open $total_exp_list\n";
while (<EXPLIST>){
  if ($_=~/(GSM\d+)/){
    push(@explist, $1)
  }
}
close EXPLIST;

#Load subspace experiment clusters
open (EXPCLUSTERS, $subspace_exp_clusters) or die "can't open $subspace_exp_clusters\n";
while (<EXPCLUSTERS>){
  chomp;
  my @cluster=split("\t", $_);
  my $cluster_id=shift @cluster;
  #If experiment names are of the form GSM46908.CEL we need to change to GSM46908
  my $i=0;
  my $cluster_size=scalar(@cluster);
  for ($i=0; $i<$cluster_size; $i++){
    if ($cluster[$i]=~/(GSM\d+)\.CEL/){
      $cluster[$i]=$1;
    }
  }
  $clusters{$cluster_id}=\@cluster;
}
close EXPCLUSTERS;

#Load experiment annotation info
open (ANNOTATIONS, $exp_annotation_info) or die "can't open $exp_annotation_info\n";
my $header_line=<ANNOTATIONS>;
while (<ANNOTATIONS>){
  my @entry=split("\t", $_);
  my $sample=$entry[0];
  my $source=$entry[1];
  $annotations{$sample}{'source'}=$source;
  $terms{$source}{$sample}++;
}
close ANNOTATIONS;

#Go through all clusters and term and summarize info for Fisher exact test
#For each cluster of exps
print "cluster\tterm\tinclust_interm\tinclust_notinterm\tnotclust_interm\tnotclust_notinterm\n";

foreach my $cluster_id (sort keys %clusters){
  my @cluster = @{$clusters{$cluster_id}};#get exps for the cluster
  my $exp_count=scalar(@cluster);
  #create list of cluster exps
  my %cluster_exps;
  foreach my $exp (@cluster){
    $cluster_exps{$exp}++;#keep track of exps in the cluster
  }
  #Determine list of exps not in cluster
  my @notcluster;
  foreach my $total_exp(@explist){
    unless ($cluster_exps{$total_exp}){#Unless each exp from the total exp list is in the cluster
      push (@notcluster, $total_exp);#add it to a notcluster list
    }
  }
  foreach my $term (sort keys %terms){
    my $inclust_interm=0;#number of exps IN the cluster that ARE annotated to a particular term
    my $inclust_notinterm=0; #number of exps IN the cluster that ARE NOT annotated to a particular term
    my $notclust_interm=0; #number of exps NOT IN the cluster that ARE annotated to a particular term
    my $notclust_notinterm=0; #number of exps NOT IN the cluster that ARE NOT annotated to a particular term

    #For each exp in the cluster determine how many are annotated or not annotated to a particular term
    foreach my $exp (@cluster){
      if ($terms{$term}{$exp}){
	$inclust_interm++;
      }
    }
    #number of exps in cluster not annotated to a term is the total number in the cluster minus those that are annotated to the term
    $inclust_notinterm=$exp_count-$inclust_interm;

    #Now, for each exp NOT in the cluster determine how many are annotated or not annotated to a particular term
    my $notclust_exp_count = scalar(@notcluster);
    foreach my $notclust_exp (@notcluster){
      if ($terms{$term}{$notclust_exp}){
	$notclust_interm++;
      }
    }
    #number of exps NOT in cluster AND not annotated to a term is the total number NOT in the cluster minus those NOT in the cluster that are annotated to the term
    $notclust_notinterm=$notclust_exp_count-$notclust_interm;
    if ($inclust_interm>=$min_inclust_interm){ #unless at least one exp in the cluster has been annotated to a particular term, by definition that term can not be significantly over-represented in the cluster
      print "$cluster_id\t$term\t$inclust_interm\t$inclust_notinterm\t$notclust_interm\t$notclust_notinterm\n";
    }
  }
}


#print Dumper (%clusters);
