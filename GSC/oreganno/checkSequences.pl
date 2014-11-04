#!/usr/bin/perl -w

use strict;

my $sites_file="FoxA2_MM0261_6L_mm8_dupsN_ht10_peaks_GOODONE_for_Oreganno.regions";
my $sequences_file="FoxA2nodups.clean.sequence";

#First, load in all sequences obtained from UCSC
my %sequences;
open (SEQUENCES, $sequences_file) or die "can't open $sequences_file\n";
$/=">";
while (<SEQUENCES>){
  if ($_=~/mm8_ct_FoxA2nodups_.+\srange\=(\w+)\:(\d+)\-(\d+).+strand\=(\S+)\srepeatMasking\=none\n(.+)\n\>/s){
    my $chr=$1;
    my $start=$2;
    my $end=$3;
    my $strand=$4;
    my $sequence=$5;
    $sequence=~s/\n//g;
    $chr=~s/chr//g;
    #print "$chr\t$start\t$end\t$strand\t$sequence\n";
    my $coord_length=($end-$start)+1;
    my $string_length=length($sequence);
    unless ($coord_length==$string_length){print "$coord_length doesn't match $string_length\n";exit;}
    $sequences{$chr}{$start}{$end}=$sequence;
  }
}
close SEQUENCES;
$/="\n";


#Now, load in all original sites. For each site there should be a corresponding sequence. 
#The sequence file could just be used but I want to make sure that all the correct sequences were obtained.
open (SITES, $sites_file) or die "can't open $sites_file\n";
while (<SITES>){
  if ($_=~/(\w+)\s+(\d+)\s+(\d+)\s+\d+/){
    my $chr=$1;
    my $start=$2;
    my $end=$3;
    my $sequence=$sequences{$chr}{$start}{$end};
    if ($sequence){
      print "$chr\t$start\t$end\t$sequence\n";
    }else{
      print "sequence not found\n"; exit;
    }
  }
}
close SITES;



