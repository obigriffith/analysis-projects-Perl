#!/usr/bin/perl -w

use strict;
use Getopt::Std;

#This script uses the annotation files provided by Affymetrix to map affy Ids to another ID

getopts("a:f:o:i:");
use vars qw($opt_a $opt_o $opt_f $opt_i);

my ($ID_type, $annotation_file,$outfile, %headings, %ID);
my $annotate_count = 0;
my $ID_count = 0;
my $map_count = 0;

unless ($opt_a && $opt_f && $opt_i){&printDocs;}

if ($opt_a){$annotation_file = $opt_a;}
if ($opt_i){$ID_type = $opt_i;}

my $datafile = $opt_f;
if ($opt_o){open (OUTFILE,">$opt_o") or die "can't open $opt_o";}

#First create a hash of affy_id -> ID mappings for fast searching
open (ANNOTATE, $annotation_file) or die "can't open $annotation_file\n";
#Determine which column contains the ID and Probe ID info from the annotation csv file
my $firstline = <ANNOTATE>;
my $match = 0;
while ($firstline =~ /\"(.+?)\"/g){  #Finds each "entry" in the csv file.
  ++$match;
  $headings{$1}=$match;
  #print "Column number $match is $1\n";
}
my $ID_col = $headings{$ID_type};
my $probe_col = $headings{"Probe Set ID"};
print "Probe Set ID found in column $probe_col of $annotation_file\n";
print "$ID_type found in column $ID_col of $annotation_file\n";

#Get probe Id and ID for each entry and put in hash.  "---" is used in affy annotation files if now ID is known
while (<ANNOTATE>){
  $annotate_count++;
  my $line = $_;
  my ($probeId, $ID);
  my $match = 0;
  while ($line =~ /\"(.+?)\"/g){
    ++$match;
#    print "comparing $match to $probe_col\n";
    if ($match==$probe_col){
      $probeId = $1;
    }
    if ($match==$ID_col){
      $ID = $1;
      if ($ID=~/\-\-\-/){next;}
      $ID_count++;
    }
  }
  #print "$probeId\t$ID\n";
  $ID{$probeId}=$ID;
}
close ANNOTATE;
print "$annotate_count lines in $annotation_file checked\n";
print "$ID_count IDs found\n";

#Now, actually go through the data file and map affy Ids to ID.
open (DATA, $datafile) or die "can't open $datafile\n";
#Just print header line
my $firstdataline = <DATA>;
if ($opt_o){print OUTFILE "$firstdataline";}
#Replace affy probe ids with ID and print to new file.
while (<DATA>){
  my $dataline = $_;
  if ($dataline =~ /^(\S+)/){
    my $probe_id = $1;
    my $ID = $ID{$probe_id};
    #Only print line to new file if actual ID found, ie a number and not "---"
    unless ($ID =~/\-\-\-/){
      $dataline =~ s/$probe_id/$ID/;
      $map_count++;
      if ($opt_o){print OUTFILE "$dataline";}
    }
  }
}
print "$map_count affy ids mapped to $ID_type in $opt_o\n";
close DATA;
close OUTFILE;
exit;

sub printDocs{
print "You must specify either -a or -b and -f filename.txt\n";
print "Options:\n";
print "-a annotationfile.txt to indicate which annotation file you wish to use for gene mapping\n";
print "-f filename.txt indicates file you wish to map\n";
print "-o outfile.txt indicates file to write newly mapped data to\n";
print "-i ID_type indicates ID that you want to map to (eg. LocusLink, Transcript ID, etc)\n";
exit;
}
