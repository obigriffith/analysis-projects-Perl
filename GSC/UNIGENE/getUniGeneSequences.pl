#!/usr/local/bin/perl -w

use strict;

#1. First get first 100 unigenes from "human_genes_missing_from_MGC.csv" to look for sequences for

my @UniGenes = ();
getMissingUnigenes(100);
#print @UniGenes;

#2. Now, get all the sequences for these unigenes

my $UniGeneSequencesFile = "/home/ybutterf/MGC/unigene/Hs.seq.all";
my $outputfile = "/mnt/disk1/home/obig/perl/UNIGENE/UnigeneSeq100.txt";
open (OUTFILE,">$outputfile") or die "can not open $outputfile";
open (UNIGENESEQ,$UniGeneSequencesFile) or die "can not open $UniGeneSequencesFile";

foreach my $unigene(@UniGenes){
  print "getting sequences for $unigene\n";
  getUniGeneSequence($unigene);

}

exit;


########################################################################
#Print sequences for unigenes to file
########################################################################
sub getUniGeneSequence{
my $unigene = shift @_;
my $unigenetemp = 0;
my $length = 0;
my $linestatus = 0;
my $threeprime = 0;

while (<UNIGENESEQ>){

  my $line = $_;
  if ($line =~ /^\n/){
    next;
  }
  if ($line =~ /^\#/){
    $linestatus=0;
    next;
  }
  if ($line =~ /^>.+\/ug=Hs\.(\d+)\s\/len=(\d+)/){
    $linestatus=0;
    $unigenetemp = $1;
    $length = $2;
    
    #Identify any sequences that have been marked as 3' end
    if ($line =~ /3\'/){
      $threeprime++;
#      print "3 prime sequence found\n";
    }
    
    if ($unigenetemp > $unigene){
      last;
    }

    if ($unigenetemp eq $unigene){
      $linestatus=1;
      print OUTFILE "$line";
      next;
    }
  }

  if ($linestatus == 1){
    print OUTFILE "$line";
    next;
  }
}
print "$threeprime 3\' sequences found\n";
return;
}
##################################################################################
#Find x number of unigenes from the MGC list of missing unigenes
#################################################################################
sub getMissingUnigenes{
my $unigenelistfile = "/mnt/disk1/home/obig/perl/UNIGENE/human_genes_missing_from_MGC.csv";
open (UNIGENELIST,$unigenelistfile) or die "can't open $unigenelistfile";

my $numbertoget = shift @_;
my $i=1;
my $unigeneID;
while ($i<=$numbertoget){
  my $line = <UNIGENELIST>;
  if ($line =~ /^(\d+),.+/){
    $unigeneID = $1;
    push (@UniGenes,$unigeneID);
    $i++;
  }
}
return;
}
