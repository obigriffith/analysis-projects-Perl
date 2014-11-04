#!/usr/local/bin/perl -w

use strict;
my $submissionID;

#Converts GSC_MGCsubmission file to fasta format and removes all phred qualities

my($USAGE) = "USAGE: getMGCfastaSequences \[filename\]\n\n";
unless(@ARGV) {
	print $USAGE;
	exit;
}

my $infile = shift @ARGV;
open(INFILE,$infile) or die "Can't open $infile";

if ($infile =~ /(.+)\.txt/){
$submissionID = $1;
}
my $outfile = $submissionID . "fasta";
open(OUTFILE,">$outfile");
my @array = <INFILE>;
foreach my $line(@array){
	if ($line =~ /^(MGC:)\s(\d+)$/){
	print OUTFILE ">".$1.$2,"\n";
	next;
	}
	if ($line =~ /^[ACGT]/){
	print OUTFILE $line;
	next;
	}
}
print "$infile converted to fasta format in $outfile\n";

close INFILE;
close OUTFILE;
exit;

