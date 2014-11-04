#!/usr/bin/perl -w

use strict;
use Getopt::Std;

#This script uses the annotation files provided by Affymetrix to map affy Ids to LocusLinks

getopts("a:f:o:i:");
use vars qw($opt_a $opt_o $opt_f $opt_i);

my $annotation_dir = "/home/obig/clustering/AFFY/human/annotations";
my ($annotation_file,$outfile,$id, %headings, %Locus);
my $annotate_count = 0;
my $locus_count = 0;
my $map_count = 0;

unless ($opt_a  && $opt_f){&printDocs;}
if ($opt_a){$annotation_file = $opt_a;}
my $datafile = $opt_f;
if ($opt_o){open (OUTFILE,">$opt_o") or die "can't open $opt_o";}
if ($opt_i){$id = $opt_i;}else{$id="LocusLink";}

#First create a hash of affy_id -> locuslinks mappings for fast searching
open (ANNOTATE, $annotation_file) or die "can't open $annotation_file\n";
#Determine which column contains the LocusLink and Probe ID info from the annotation csv file
my $firstline = <ANNOTATE>;
my $match = 0;
while ($firstline =~ /\"(.+?)\"/g){  #Finds each "entry" in the csv file.
  ++$match;
  $headings{$1}=$match;
  #print "Column number $match is $1\n";
}
my $id_col = $headings{"$id"};
my $probe_col = $headings{"Probe Set ID"};
print "Probe Set ID found in column $probe_col of $annotation_file\n";
print "$id found in column $id_col of $annotation_file\n";

#Get probe Id and Locus Link for each entry and put in hash.  "---" is used in affy annotation files if now Locuslink is known
while (<ANNOTATE>){
  $annotate_count++;
  my $line = $_;
  my ($probeId, $locuslink);
  my $match = 0;
  while ($line =~ /\"(.+?)\"/g){
    ++$match;
#    print "comparing $match to $probe_col\n";
    if ($match==$probe_col){
      $probeId = $1;
    }
    if ($match==$id_col){
      $locuslink = $1;
      if ($locuslink =~/\d+/){$locus_count++;}
    }
  }
  #print "$probeId\t$locuslink\n";
  $Locus{$probeId}=$locuslink;
}
close ANNOTATE;
print "$annotate_count lines in $annotation_file checked\n";
print "$locus_count LocusLinks found\n";

#Now, actually go through the data file and map affy Ids to locuslinks.
open (DATA, $datafile) or die "can't open $datafile\n";
#Just print header line
my $firstdataline = <DATA>;
if ($opt_o){print OUTFILE "$firstdataline";}
#Replace affy probe ids with locuslinks and print to new file.
while (<DATA>){
  my $locus = "";
  my $dataline = $_;
  if ($dataline =~ /^(\S+)/){
    my $probe_id = $1;
    $locus = $Locus{$probe_id};
    #Only print line to new file if actual locuslink found, ie a number and not "---"
    if ($locus =~/\d+/){
      $dataline =~ s/$probe_id/$locus/;
      $map_count++;
      if ($opt_o){print OUTFILE "$dataline";}
    }
  }
}
print "$map_count affy ids mapped to LocusLinks in $opt_o\n";
close DATA;
close OUTFILE;
exit;

sub printDocs{
print "You must specify either -a or -b and -f filename.txt\n";
print "Options:\n";
print "-a to indicate which annotation file you wish to use for gene mapping\n";
print "-f filename.txt indicates file you wish to map\n";
print "-o outfile.txt indicates file to write newly mapped data to\n";
print "-i to indicate which ID to map to (eg. Ensembl ID), default=LocusLink\n";
exit;
}
