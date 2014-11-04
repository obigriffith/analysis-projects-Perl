#!/usr/bin/perl -w

use strict;
use Getopt::Std;

getopts("f:o:");
use vars qw($opt_f $opt_o);
use strict;

$| = 1;

my $file;
my $outfile;
if ($opt_f){$file = $opt_f;}else{&printDocs();}
if ($opt_o){$outfile = $opt_o;}

if ($opt_o){
  open (OUTFILE, ">$outfile") or die "can't open $outfile for write\n";
}

open(DATA,"$file");

my @IDS;
my $firstline = <DATA>;  # Skip the title line
while(<DATA>) {
  if (/^(\S+)/){
    push(@IDS,$1);
  }
}

open(OUTPUT,"/home/obig/bin/Cluster/cluster-1.23/local2/bin/cluster -f $file -g 2 -e 0 -u $outfile |");
while (<OUTPUT>) {
  if (/^DISTANCE\s+(\d+)\s+(\d+)\s+(\S*)/) { #changed so that -ve and +ve correlations are considered.
    print "$IDS[$1]\t$IDS[$2]\t$3\n";
    if ($opt_o){
      print OUTFILE "$IDS[$1]\t$IDS[$2]\t$3\n";
    }
  }
}
close OUTPUT;

if ($opt_o){
  close OUTFILE;
}

exit;

sub printDocs{
print "\nMust supply file names (cluster_wrapper.pl -f filename.txt -o output.txt)\n";
exit;
}
