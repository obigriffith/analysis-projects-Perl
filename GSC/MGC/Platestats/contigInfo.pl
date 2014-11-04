#!/usr/local/bin/perl -w
# simple script to parse an Ace file to a text summary
# shows number of contigs, length and reads for each, and other statistics
# Uses modified get_Contigs_from_Ace subroutine from AceParse.pm
#
#


use lib '/mnt/disk1/home/obig/perl_stuff';
use AceParser;
use strict;

my $outputfile = "./plateinfo.txt";
my $answer2 eq "y";
my $status = 1;

print "This script will report various statistics for an assembly.\n";
print "Delete previous output file plateinfo.txt? \(y\)";
my $answer = <STDIN>;
chomp $answer;

if ($answer eq "y"){
unlink $outputfile;
print "\nfile deleted\n";
}

while ($status = 1){
print "Run Script?";
$answer2 = <STDIN>;
chomp $answer2;
if ($answer2 eq "n"){
exit;
} 

print "Enter the source directory. eg. IRAK70a\n";
my $filedir = <STDIN>;
chomp $filedir;
 
print "Enter the name of the assembly file to be analyzed.\n eg.21614a.fasta.screen.ace.12 \(use the most recent version\)\n";
my $file = <STDIN>;
chomp $file;

print "The results of the analysis will be printed to the file plateinfo.txt in your current directory\n";

my $inputfile = "/home/sequence/Projects/Human_cDNA/Assemblies/$filedir/edit_dir/$file";

#Check to make sure Output file can be opened and add plate name to file before 
#analysis proceeds
unless ( open(OUTFILE, ">>$outputfile") ){
  print "Cannot open file \"$outputfile\" to write to !\n\n";
  exit;
}
print OUTFILE ">>>$filedir\n";
close OUTFILE;

#Check to make sure that Input file exists before analysis proceeds
open ( INFILE, $inputfile) or die "Cannot open file $file\n";
close INFILE;

$status = get_Contigs_from_Ace($inputfile,$outputfile);
}
exit;

