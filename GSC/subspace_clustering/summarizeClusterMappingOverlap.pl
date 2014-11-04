#!/usr/bin/perl -w

use strict;
use Data::Dumper;
use Getopt::Std;

getopts("f:m:d:t:v");
use vars qw($opt_f $opt_m $opt_d $opt_t $opt_v);
unless(($opt_f || $opt_d) && $opt_m){&printDocs();}
if ($opt_d){unless ($opt_t){&printDocs();}}

sub printDocs{
print "usage: summarizeClusterMappingOverlap.pl -f clusterfile -m mapping file
options:
-d specify a directory of cluster files instead of a single file
-t If directory option is used, specify the data to output (1=mean repeats per cluster; 2=cumulative fraction of clusters with repeat)
-v flag for verbose output.  Prints repeat numbers for each cluster instead of just summaries.
";
exit;
}

#This script will load a file for mapping probe clusters to genes/proteins and summarize the results in terms of overlapping mappings
my $mapping_file = $opt_m;
my @cluster_files;
my %mean_repeat_summary; #Mean repeats for all cluster sizes for all cluster files
my %cum_cluster_repeat_fraction_summary; #Cumulative cluster repeat fraction for all cluster sizes and all cluster files
my %cluster_sizes;
#Prepare to load clusterfiles (either a single file or directory of files)
if ($opt_f){
  push (@cluster_files, $opt_f);
}
if ($opt_d){
  @cluster_files=`ls $opt_d`;
}

#First, load mapping file
my %probe_gene_map;
open (MAPFILE, $mapping_file) or die "can't open $mapping_file\n";
while (<MAPFILE>){
chomp $_;
my @entry = split ("\t", $_);
my $probe = $entry[0];
my $gene = $entry[1];
$probe_gene_map{$probe}=$gene; #Warning - be aware that if a probe has more than one gene/protein, only one will be kept
}
close MAPFILE;
#print Dumper (%probe_gene_map);

foreach my $cluster_file (@cluster_files){
chomp $cluster_file;
if ($opt_d){$cluster_file="$opt_d/"."$cluster_file";}
  #Now load cluster file and map probes to genes/proteins.
  my %repeat_summary;
  my %cluster_summary;
  my %cluster_repeat_count;
  my $total_cluster_number=0;
  open (CLUSTERFILE, $cluster_file) or die "can't open $cluster_file\n";
  while (<CLUSTERFILE>){
    chomp $_;
    my @probe_cluster = split ("\t", $_);
    my @gene_cluster;
    my $total_repeated_genes=0;
    foreach my $probe (@probe_cluster){
      if ($probe_gene_map{$probe}){
	my $gene = $probe_gene_map{$probe};
	push (@gene_cluster, $gene);
      }
    }
    if (@gene_cluster>1){#Only clusters that still have more than one probe retained.  If only mappable probes were used, this will have no effect
      $total_cluster_number++;
      my $cluster_size=@gene_cluster;
      #print join ("\t", @gene_cluster), "\n";

      #Determine how many times each gene is observed in each mapped cluster
      my %repeatcount;
      foreach my $mapped_gene (@gene_cluster){
	$repeatcount{$mapped_gene}++;
      }
      foreach my $gene (keys %repeatcount){
	if ($repeatcount{$gene}>1){
	  #print "$repeatcount{$gene} repeated genes found\n";
	  $total_repeated_genes+=$repeatcount{$gene};
	  $cluster_repeat_count{$cluster_size}++; #Keep track of number of clusters with a repeated gene for each cluster size.
	}
      }
      #print "cluster $total_cluster_number has $cluster_size total genes and $total_repeated_genes total repeated genes\n";
      if ($opt_v){print "$total_cluster_number\t$cluster_size\t$total_repeated_genes\n";}
      #Keep a running total of repeated genes and numbers of clusters for each size of cluster
      $repeat_summary{$cluster_size}+=$total_repeated_genes;
      $cluster_summary{$cluster_size}++;
    }
  }
  close CLUSTERFILE;

  #Finally, print summary of gene repeat frequency for all cluster sizes
  if ($opt_f){
    print "Cluster_size\tNumber_clusters\ttotal_gene_repeats\tnumber_clusters_with_gene_repeat\tcum_cluster_repeat_fraction\tmean_repeats\n";
    my $cum_cluster_repeat_fraction=0;
    foreach my $cluster_size (sort{$a<=>$b} keys %cluster_summary){
      my $cluster_repeat_count=0;#Assume no repeats for the clustersize
      if ($cluster_repeat_count{$cluster_size}){#If cluster size had repeats replace zero with the number
	$cluster_repeat_count=$cluster_repeat_count{$cluster_size};
      }
      #summarize numbers for each cluster size
      my $number_clusters=$cluster_summary{$cluster_size};
      my $total_gene_repeats=$repeat_summary{$cluster_size};
      $cum_cluster_repeat_fraction+=($cluster_repeat_count/$total_cluster_number);
      my $mean_repeats=$total_gene_repeats/$number_clusters;
      print "$cluster_size\t$number_clusters\t$total_gene_repeats\t$cluster_repeat_count\t$cum_cluster_repeat_fraction\t$mean_repeats\n";
    }
  }

  if ($opt_d){ #If multiple input files, just summarize and print later
    #print "processing: $cluster_file\n";
    my $cum_cluster_repeat_fraction=0;
    foreach my $cluster_size (sort{$a<=>$b} keys %cluster_summary){
      $cluster_sizes{$cluster_size}++;#Keep track of all cluster sizes
      my $cluster_repeat_count=0;#Assume no repeats for the clustersize
      if ($cluster_repeat_count{$cluster_size}){#If cluster size had repeats replace zero with the number
	$cluster_repeat_count=$cluster_repeat_count{$cluster_size};
      }
      #summarize numbers for each cluster size
      my $number_clusters=$cluster_summary{$cluster_size};
      my $total_gene_repeats=$repeat_summary{$cluster_size};
      $cum_cluster_repeat_fraction+=($cluster_repeat_count/$total_cluster_number);
      my $mean_repeats=$total_gene_repeats/$number_clusters;
      $mean_repeat_summary{$cluster_file}{$cluster_size}=$mean_repeats;
      $cum_cluster_repeat_fraction_summary{$cluster_file}{$cluster_size}=$cum_cluster_repeat_fraction;
    }
  }
}

if ($opt_d){
  my @cluster_sizes=sort{$a<=>$b} keys %cluster_sizes;
  print join("\t", @cluster_sizes), "\n";
  foreach my $cluster_file (sort keys %mean_repeat_summary){
    my @data;
    foreach my $cluster_size (sort{$a<=>$b} keys %{$mean_repeat_summary{$cluster_file}}){
      if ($opt_t==1){
	push (@data, $mean_repeat_summary{$cluster_file}{$cluster_size});
      }
      if ($opt_t==2){
	push (@data, $cum_cluster_repeat_fraction_summary{$cluster_file}{$cluster_size});
      }
    }
    print join("\t", @data), "\n";
  }
}
