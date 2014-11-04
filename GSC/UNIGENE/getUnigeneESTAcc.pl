#!/usr/local/bin/perl -w

use strict;

my $outfile = "Unigene_EST_Accessions.txt";
my $mgc_missing_genes_file = "/home/ybutterf/MGC/unigene/human_genes_missing_from_MGC.csv";
my $unigene_data_file = "/home/ybutterf/MGC/unigene/Hs.data";

open (OUTFILE, ">$outfile") or die "can't open $outfile";
open (MGCMISSING,$mgc_missing_genes_file) or die "can't open $mgc_missing_genes_file";
open (UNIGENEDATA,$unigene_data_file) or die "can't open $unigene_data_file";

#Get first 100 Unigene IDs that MGC is interested in from human_genes_missing_from_MGC.csv
#and put them all into an array.
my $i =1;
my $unigeneID;
my @unigene;
while ($i<=100){
  my $line = <MGCMISSING>;
  if ($line =~ /^(\d+),.+/){
    $unigeneID = $1;
#    print "$i,$unigeneID\n";
    push (@unigene,$unigeneID);
    $i++;
  }
}

#Parse EST accession numbers to an output file
print "Determining EST accession numbers for the following UNIGENE IDs\n";
print "@unigene";
my $match = 0;
my $tempid = 0;

foreach my $id(@unigene){
  print OUTFILE "Unigene ID: $id\n";
  while (<UNIGENEDATA>){
    my $line = $_;
    chomp($line);
    if ($line =~ /^ID\s+Hs\.(\d+)$/){
      $tempid = $1;
      if ($tempid == $id){
	$match = 1;
      }
      next;
    }

    if ($line =~ /^SEQUENCE\s+ACC\=(.+)\;\s+NID.+/){
      if ($match == 1){
	print OUTFILE "EST accession number: $1\n";
      }
      next;
    }

    if ($line =~ /^\/\/$/){
      if ($match == 1){
	$match = 0;
	last;
      }
    }
    if ($tempid > $id){
      last;
    }
  }
}


close MGCMISSING;
close UNIGENEDATA;
exit;

