#!/usr/bin/perl -w

use strict;
use Data::Dumper;
use Getopt::Long;

my $fastq_file = '';

GetOptions ('fastq_file=s'=>\$fastq_file);

open (FILE1, $fastq_file) or die "can't open $fastq_file\n";
#Read in four lines at a time of fastq file
my @lines;
while (<FILE1>){
  chomp;
  push (@lines, $_);
  if (@lines==4){
    my $read1;
      if($lines[0]=~/\@\S+\:(\d+)\:(\d+)\:(\d+)\:(\d+)\#\d+\/(\d+)/){
        $read1 = "$1\t$2\t$3\t$4";
        }else{print "unexpected fastq format: $lines[0]\n";}
        my $sequence1=$lines[1];
        if($sequence1=~/[^ACTGN]/){print "unexpected sequence: $sequence1\n";}
        my $quality_string1=$lines[3];
        @lines = ();  # clear
      }
  }
close FILE1;

