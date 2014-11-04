#!/usr/bin/perl

=head1 NAME

  	findCommonGOTerms.pl

=head1 SYNOPSIS
	
	findCommonGOTerms.pl -f -a
	
=head1 ARGUMENTS

	
  file: supply file of gene pairs to examine for common GO terms	
  annotations: supply annotations file mapping gene IDs to GO terms
  		
=head1 DESCRIPTION

Takes a list of gene pairs and determines what GO terms they share if any

=head1 AUTHOR

  	O.L. Griffith
  	University of British Columbia
  	E-mail: obig@bcgsc.ca

=cut

use POSIX;
use strict;
use constant VERSION => "findCommonGOTerms.pl 1.0";
use constant DEBUG 		=> 0;
use constant USAGE 		=> "findCommonGOTerms.pl -f genepairs.txt -a gene_GO_annotations.txt\n";
use Data::Dumper;
use Getopt::Std;
getopts("f:o:a:");
use vars qw($opt_o $opt_f $opt_a);
unless ($opt_f && $opt_a){&printDocs();}

my $gene_GO_annotations = $opt_a; #make sure that the annotations are as complete as possible for the gene list provided.  Provide a complete list of unique genes to CreateGO_Associations.pl
my $gene_pair_list = $opt_f;
if ($opt_o){open (OUTFILE, ">$opt_o") or die "can't open $opt_o for output\n";}
my %annotations;
my ($gene_pairs_count,$annotated_pairs_count, $common_annotation_count);

#store GO annotations in a hash of arrays
open (GOANNOTATE, $gene_GO_annotations) or die "can't open $gene_GO_annotations\n";
while (<GOANNOTATE>){
  my $line = $_;
  if ($line=~/(\S+)\s+GO.*/){
    my $id = $1;
    my @GO;
    while ($line=~m/(GO\:\d+)/g){
      push (@GO, $1);
    }
    $annotations{$id}=\@GO;
    #print "$id\t",join ("\t",@GO),"\n";
  }
}

#Foreach genepair in the gene list, check to see if any GO annotations exist
open (GENEPAIRLIST, $gene_pair_list) or die "can't open $gene_pair_list\n";
while (<GENEPAIRLIST>){
  my (@GO_annot1,@GO_annot2);
  $gene_pairs_count++;
  if ($_=~/(\S+)\s+(\S+)\s+(\S+)/){
    my $gene1 = $1;
    my $gene2 = $2;
    my $pearson = $3;
    $gene_pairs_count++;
    #Check for GO annotations and skip pair if not found
    unless ($annotations{$gene1}){next;}
    unless ($annotations{$gene2}){next;}
    #dereference GO annotation arrays
    my $GO_annot_ref1 = $annotations{$gene1};@GO_annot1 = @$GO_annot_ref1;
    my $GO_annot_ref2 = $annotations{$gene2};@GO_annot2 = @$GO_annot_ref2;
    $annotated_pairs_count++;
    #compare annotation arrays to find common annotations
    my $common_check=0; my @Common_GO;
    foreach my $annot1 (@GO_annot1){
      foreach my $annot2 (@GO_annot2){
	if ($annot1 eq $annot2){
	  push (@Common_GO, $annot1);
	  $common_check=1;
	}
      }
    }
    if ($common_check==1){
      print "$gene1\t$gene2\t$pearson\t",join ("; ", @Common_GO),"\n";
      if ($opt_o){print OUTFILE "$gene1\t$gene2\t$pearson\t",join ("; ", @Common_GO),"\n";}
    }
  }else{print"$gene_pair_list not in expected format \"gene1 gene2\"\n";exit;}
}
if ($opt_o){close OUTFILE;}
exit;

sub printDocs{
print "This script determines which gene pairs share a common GO term.
You must make sure that the annotation file is complete for your gene pair list by running Create_GO_Associations.pl with your complete gene list
you must supply the follwing options:
-f genelist
-o output file
-a GO annotation file\n";
exit;
}

