#!/usr/local/bin/perl -w

use strict;
use Data::Dumper;

my $mapfile = "/home/obig/Projects/clustering/GO/GO_annotations/gene_association.goa_human.20050425.genelist2ENSG.unambig";
my $matrixfile = "/home/obig/Projects/clustering/GO/GO_proxy/04290910May2005.unambig_genes.allterms_noIEA_ND_NR.dicematrix";
my $outfile = "/home/obig/Projects/clustering/GO/GO_proxy/04290910May2005.unambig_genes.allterms_noIEA_ND_NR.dicematrix.ENSG";
my %MAP;

open (MAPFILE, $mapfile) or die "can't open $mapfile\n";
while (<MAPFILE>){
  if ($_=~/(\S+)\s+(\S+)\s+(\S+)/){
    $MAP{$1}=$3;
  }
}
close MAPFILE;

open (OUTFILE, ">$outfile") or die "can't open $outfile\n";
open (MATRIX, $matrixfile) or die "can't open $matrixfile\n";

my $firstline = <MATRIX>; #Get column headers and replace with ENSG IDs
chomp $firstline;
my @col_headers = split ("\t",$firstline);
my $size = scalar @col_headers;
my @new_col_headers;

for (my $i=1; $i<$size; $i++){ #index 0 is empty, otherwise go to last entry (which is $size-1)
  my $GO_gene=$col_headers[$i];
  my $ENSG_gene=$MAP{$GO_gene};
  push (@new_col_headers, $ENSG_gene);
  #print "$GO_gene\t$ENSG_gene\n";
}
print OUTFILE "\t",join("\t",@new_col_headers),"\n";

#Now, go through the rest of the lines and replace each row header
while (<MATRIX>){
  my $line = $_;
  if ($line=~/^(\S+)\s+/){
    my $GO_gene=$1;
    my $ENSG_gene = $MAP{$GO_gene};
    #print "$GO_gene\t$ENSG_gene\n";
    $line =~ s/$GO_gene/$ENSG_gene/;
    print OUTFILE $line;
  }
}
close MATRIX;
close OUTFILE;
