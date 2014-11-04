#!/usr/bin/perl

use strict;
use Data::Dumper;
use Getopt::Std;


getopts("i:o:s:e:n");
use vars qw($opt_i $opt_o $opt_s $opt_e $opt_n);

unless ($opt_i && $opt_o){print "must supply infile and outfile with -o and -i";exit;}

my $infile = $opt_i;
my $outfile = $opt_o;
my $start = $opt_s;
my $end = $opt_e;
my $i = 1;

#Determine number of columns to be transposed to rows.
open (INFILE, "$infile") or die "can't open $infile\n";

open (OUTFILE, ">$outfile") or die "can't open $outfile\n";
my $j =0;
for ($i=$start; $i<=$end; $i++){
  print "\ncut -f $i $infile\n";
  my $k=0;
  my @array = `cut -f $i $infile`;
  my $array_size=@array;
  unless ($j==0){
    #print "\n";
    print OUTFILE "\n";
  }
  foreach my $line (@array){
    $k++;
    chomp $line;
    if ($opt_n){
      if ($line eq 0){$line="";} #Replace any zeros with null
    }
    if ($k<$array_size){
      print OUTFILE "$line\t";
    }else{
      print OUTFILE "$line";
    }
    #print "$line\t";
  }
  $j++;
}

close OUTFILE;
exit;
