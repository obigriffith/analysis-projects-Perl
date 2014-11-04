#!/usr/bin/perl -w

use strict;
use Data::Dumper;
use Getopt::Std;

#Simpler than bestmatch_wrapper.pl - assumes output from bestmatch script will have neighborhoods

$|=1;

getopts("a:b:o:n:i:t:");
use vars qw($opt_a $opt_b $opt_n $opt_o $opt_i $opt_t);

unless ($opt_a && $opt_b && $opt_o && $opt_n && $opt_i && $opt_t){&printDocs();}

my $bestmatch_script = "/home/obig/clustering/bestmatch/bestMatch6_storable_multiple.pl";
my $file_a = $opt_a;
my $file_b = $opt_b;
my $n = $opt_n;
my $summary_file = $opt_o;
my $iterations = $opt_i;
my $tempfile = $opt_t;

for (my $i=1; $i<=$iterations; $i++){
#print "$bestmatch_script -a $file_a -b $file_b -n $n -r\n";
print "\n\nrunning bestmatch rep: $i\n";
open (SUMMARY, ">>$summary_file");
print SUMMARY "$i";
system("$bestmatch_script -a $file_a -b $file_b -n $n -r > $tempfile");
open (TEMPFILE, $tempfile);
while (<TEMPFILE>){
  if ($_=~/(\S+)\s+(\S+)\s+(\S+)/){
    print "$_";
    print SUMMARY "\t$3";
  }
}
print SUMMARY "\n";
close SUMMARY;
close TEMPFILE;
unlink $tempfile;
}

exit;

sub printDocs{
print "\nYou must specify the following options:
-a platform a results file in .storable format
-b platform b results file in .storable format
-o output file for summary of multiple randomizations
-i number of iterations to perform
-t tempfile for each output (deleted automatically)
-n neighborhood size\n";
exit;
}
