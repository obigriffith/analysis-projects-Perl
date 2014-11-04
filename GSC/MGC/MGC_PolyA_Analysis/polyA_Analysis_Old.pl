#!/usr/local/bin/perl -w

#use strict;
my $MGCsequencesfile = "testseq";
#my $MGCsequencesfile = "/home/pubseq/databases/MGC_clones/MGC.sequences";
my $emboss = "/home/pubseq/BioSw/EMBOSS/020821/EMBOSS-2.5.0/emboss";
my $chimericmotif = "{A}A'(10,150)'CTCGAG";
my $polyAmotif = "{A}A'(10,150)''>'";
my $tempchimeric = "tempchimeric";
my $temppolyA = "temppolyA";


RunFuzznucOnMotif($MGCsequencesfile,$chimericmotif,$tempchimeric);
RunFuzznucOnMotif($MGCsequencesfile,$polyAmotif,$temppolyA);

exit;



####################################################################################
#Subroutine to run EMBOSS-fuzznuc to determine occurence of a motif in a sequence
#eg. polyA region within sequence indicating chimeric clone
####################################################################################
sub RunFuzznucOnMotif {

my $file = shift @_;
my $motif = shift @_;
my $tempfile = shift @_;
my $position = 0;
my $length = 0;

`$emboss/fuzznuc -sequence $file -pattern $motif -mismatch 0 -rformat2 simple -outfile $tempfile -rdesshow`;

#my $tempfile = "tempfuzz";
#open (TEMPFUZZ,$tempfile);

#my $motifregioncount = 0;

#while (<TEMPFUZZ>){
#  my $line = $_;
#  if ($line =~/^Start:\s+(\d+)/){
#    $position = $1;
#    $motifregioncount++;
#    }
#  if ($line =~/^Length:\s+(\d+)/){
#    $length = $1 - 7;
#  }
#
#}
#close TEMPFUZZ;
#unlink "tempfuzz";
return;

}
