#!/usr/bin/perl -w

use strict;

use Getopt::Std;
use Data::Dumper;
getopts("r:p:o:t:h");
use vars qw($opt_r $opt_p $opt_o $opt_t $opt_h);

my ($ratio_file, $pvalue_file, $outfile, $threshold);

unless ($opt_r){&printDocs()};
if ($opt_h){&printDocs()};

if ($opt_r){$ratio_file = $opt_r;}
if ($opt_p){$pvalue_file = $opt_p;}
if ($opt_o){$outfile = $opt_o;}
if ($opt_t){$threshold = $opt_t;}

open (RATIOS, $ratio_file) or die "can't open $ratio_file\n";
#First line should contain the word Tag followed by lib_x/lib_y
my $header = <RATIOS>;
chomp $header;
my @libnames = split ('\t', $header);

while (<RATIOS>){
my $nextline = $_;
chomp $nextline;
my @data = split ('\t', $nextline);
print Dumper(@data);
}










sub printDocs{
print "This script searches a ratio file output from sagematrix.sh for tags with exclusively high expression in one (or more) library\n";
print "Options:\n";
print "-r ratiofile\n";
print "-p p-value file\n";
print "-o output file\n";
print "-t specify threshold (minimum fold change)\n";
print "-h prints this help document\n";
exit;
}



