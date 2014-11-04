#!/usr/bin/perl -w

use strict;

use Getopt::Std;
getopts("f:g:d:o:l");
use vars qw($opt_f $opt_g $opt_d $opt_o $opt_l);

unless ($opt_f && $opt_g && $opt_d){print "Must supply file name and minimum number of genes/dimensions for subspace cluster\nUsage parseSigFile.pl -l -g 2 -d 10 -f Kiwi_output.sig -o output_base_name [-l option adds cluster names to output files]\n";exit;}

my %Data;
my ($geneclusterfile, $expclusterfile);

if ($opt_o){
  $geneclusterfile = "$opt_o"."_genes.txt";
  $expclusterfile = "$opt_o"."_exps.txt";
  open (GENECLUSTERS, ">$geneclusterfile") or die "can't open $geneclusterfile\n";
  open (EXPCLUSTERS, ">$expclusterfile") or die "can't open $expclusterfile\n";
}

open (SIGFILE, $opt_f) or die "can't open $opt_f\n";

my $i=0;
my ($genes, $dimensions, $cluster, $num_genes, $num_dimensions);
while (<SIGFILE>){
  my $line=$_;
  chomp $line;
  if ($line=~/Cluster\s(\d+)\:\s(\d+)\sgenes\sshare\s(\d+)\sdimensions/){
    $cluster=$1; $num_genes=$2; $num_dimensions=$3;
    #print "Cluster:$cluster\tGenes:$num_genes\tDimensions:$num_dimensions\n";
    $i++;
    next;
  }
  if ($i==1){
    $dimensions=$line;
    $i++;
    next;
  }
  if ($i==2){
    $genes=$line;
    $Data{$cluster}{'num_genes'}=$num_genes;
    $Data{$cluster}{'num_dimensions'}=$num_dimensions;
    $Data{$cluster}{'genes'}=$genes;
    $Data{$cluster}{'dimensions'}=$dimensions;

    #In some cases, the genes in a cluster may be non-unique (because of mapping issues)
    my @genelist = split ("\t",$genes);
    foreach my $gene (@genelist){
      $Data{$cluster}{'uniqgenes'}{$gene}++;
    }
    $Data{$cluster}{'num_uniq_genes'}=keys %{$Data{$cluster}{'uniqgenes'}};
    $i=0;
    next;
  }
}

close SIGFILE;

foreach my $cluster (sort{$a<=>$b} keys %Data){
  if ($Data{$cluster}{'num_uniq_genes'} >= $opt_g && $Data{$cluster}{'num_dimensions'}>=$opt_d){
    print "cluster: $cluster genes: $Data{$cluster}{'num_genes'} unique genes: $Data{$cluster}{'num_uniq_genes'} dimensions: $Data{$cluster}{'num_dimensions'}\n";
    if ($opt_o){
      if ($opt_l){
	print GENECLUSTERS "cluster"."$cluster\t"."$Data{$cluster}{'genes'}\n";
	print EXPCLUSTERS "cluster"."$cluster\t"."$Data{$cluster}{'dimensions'}\n";
      }else{
	print GENECLUSTERS "$Data{$cluster}{'genes'}\n";
	print EXPCLUSTERS "$Data{$cluster}{'dimensions'}\n";
      }
    }
  }
}

if ($opt_o){
  close GENECLUSTERS;
  close EXPCLUSTERS;
}
