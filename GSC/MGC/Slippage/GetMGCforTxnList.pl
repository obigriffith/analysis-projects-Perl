#!/usr/local/bin/perl -w

use strict;
use lib "/home/ybutterf/perl/lib";
use cDNA::Clones;
use Data::Dumper;

print "\nenter file containing list of reads for which you want to know MGC numbers:\n";

my $txnlistfile = <STDIN>;
chomp $txnlistfile;
open(TXNLIST, $txnlistfile) or die "Can't open $txnlistfile";
my @Alltxnlist = <TXNLIST>;
close TXNLIST;

print "enter name of output file\n";
my $outfile = <STDIN>;
chomp $outfile;

open(OUTFILE,">$outfile") or die "Can't open $outfile";

#make a separate array for each set of blocked txns ie. for 7,8,9,10etc.
foreach $txn1


#Remove endlines and file extension from array of transposon reads
my $txn;
foreach $txn(@txnlist){
$txn =~ s/\n//g;
$txn =~ s/\.phd\.2//g;
}

my @mgc_clones = Clones::get_MGC_from_assembled_read(@txnlist);

print OUTFILE "@mgc_clones";
print "\nThe following clones were output to $outfile:\n@mgc_clones\n";

close OUTFILE;
exit;
