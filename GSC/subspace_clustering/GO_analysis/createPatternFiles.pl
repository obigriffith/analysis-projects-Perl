#!/usr/bin/perl -w

use strict;
use Getopt::Std;

getopts("d:o:n:");
use vars qw($opt_d $opt_o $opt_n);

my $dir = $opt_d; #location of files to put in pattern files
my $output_dir = $opt_o; #location for creation of pattern files
my $n = $opt_n; #Number of files per pattern file

my @files = `ls $dir`;

my $i=1;
my $j=1;
my $pattern_file_base="pattern";

foreach my $file (@files){
  chomp $file;
  if ($file=~/\d+\.txt/){
    if ($i>$n){$j++; $i=1;}
    my $outfile = "$output_dir/"."$pattern_file_base"."$j";
    open (OUTFILE, ">>$outfile") or die "can't open $outfile\n";
    print "$outfile: $file\n";
    print OUTFILE "$file\n";
    close OUTFILE;
    $i++;
  }
}
