#!/usr/local/bin/perl56 -w
#!/usr/bin/perl -w

use strict;
use Data::Dumper;
use Getopt::Std;

getopts("f:m:");
use vars qw($opt_f $opt_m);

#This script will load a file for mapping Genes to proteins (that GO understands for example)


#First, load mapping file
my $mapping_file = $opt_m;
my $cluster_file = $opt_f;
my %gene_prot_map;

open (MAPFILE, $mapping_file) or die "can't open $mapping_file\n";
while (<MAPFILE>){
chomp $_;
my @entry = split ("\t", $_);
my $gene = $entry[2];
my $protein = $entry[0];
$gene_prot_map{$gene}=$protein; #Warning - be aware that if a gene has more than one protein, only one will be kept
}
close MAPFILE;

#print Dumper (%gene_prot_map);

#Now load cluster file and map genes to clusters.
open (CLUSTERFILE, $cluster_file) or die "can't open $cluster_file\n";
while (<CLUSTERFILE>){
  chomp $_;
  my @prot_cluster;
  my @gene_cluster = split ("\t", $_);
  foreach my $gene (@gene_cluster){
    if ($gene_prot_map{$gene}){
      my $protein = $gene_prot_map{$gene};
      push (@prot_cluster, $protein);
    }
  }
  if (@prot_cluster>1){
    print join ("\t", @prot_cluster), "\n";
  }
}
close CLUSTERFILE;
