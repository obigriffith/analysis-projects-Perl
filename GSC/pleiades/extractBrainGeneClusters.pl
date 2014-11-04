#!/usr/bin/perl -w

use strict;
use Data::Dumper;
use Getopt::Std;
getopts("f:g:");
use vars qw($opt_f $opt_g);

my $datafile=$opt_f;
my $genelist=$opt_g;
my %Genes;

#Get list of genes of interest
open (GENES, $genelist) or die "can't open $genelist\n";
my $header = <GENES>; #skip first line
while (<GENES>){
  chomp;
  my @data = split("\t", $_);
  my $ENSG=$data[1];
  my $ENSMUSG=$data[3];
  if ($ENSG=~/ENSG/){$Genes{$ENSG}++;}
  if ($ENSMUSG=~/ENSMUSG/){$Genes{$ENSMUSG}++;}
}
close GENES;

#Go through clusterfile and extract only clusters with one or more genes of interest
open (DATAFILE, $datafile) or die "can't open $datafile\n";
while(<DATAFILE>){
  my $line=$_;
  while ($line=~m/((ENSG|ENSMUSG)\d+)/g){
    if ($Genes{$1}){
      print $line;
      last; #If one gene in the cluster is of interest go to the next line.
    }
  }
}

close DATAFILE;
