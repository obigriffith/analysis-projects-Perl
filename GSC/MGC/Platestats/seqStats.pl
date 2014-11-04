#!/usr/local/bin/perl -w

#This script should run EMBOSS programs infoseq and fuzznuc on some sequence and output
#the results to a file

use strict;
use lib "/home/ybutterf/perl/lib";
use cDNA::Clones;

my $emboss = "/home/pubseq/BioSw/EMBOSS/020821/EMBOSS-2.5.0/emboss";
my $outputfile = "/mnt/disk1/home/obig/www/cgi-bin/intranet/plateinfo.txt";
open (OUTPUTFILE, ">$outputfile")or die "Can't open $outputfile";

print "\nThis script will return various general statistics for all the finished sequences of a plate.  The results are output to the file Platesummary.txt\n";

my @plates = qw(IRAL6 IRAL8 IRAL9 IRAL13 IRAL18 IRAL22 IRAL23 IRAL29 IRAK15 IRAL34 IRAK38 IRAL40 IRAK57 IRAL42 IRAK67 IRAK70 IRAK75 IRAL43 IRAK76);

while (@plates){
my $plate = shift @plates;
#print "\nEnter plate \(eg. IRAK75\)";
#my $plate = <STDIN>;
#chomp $plate;

print OUTPUTFILE "\n>>>$plate";
my $plate_id = ConvertPlateNameToPlateID($plate);


#Declare motifs to search for in format that EMBOSS-fuzznuc will understand
#To eliminate overlapping matches the motifs specified here require a non-matching component
#at the start and end of the motif overall. Example, the first motif is as follows.
#One base that is not A or T, followed by 10-100 A's or T's, followed by one base that is not A or T
#this ensures that each AT region is counted only once
my $ATmotif = "{AT}[AT]'(10,100)'{AT}";
my $GCmotif = "{GC}[GC]'(10,100)'{GC}";
my $polyAmotif = "{A}A'(10,100)'{A}";
my $polyCmotif = "{C}C'(10,100)'{C}";
my $polyGmotif = "{G}G'(10,100)'{G}";
my $polyTmotif = "{T}T'(10,100)'{T}";

#Declare variables that will tallied up each time through the foreach Clone loop

my $clonecount = 0;
my $grandlength = 0;
my $totalpgc = 0;
my $highPGCclones = 0;

my $totalGC = 0;
my $totalGCbases = 0;
my $highGCclones = 0;

my $totalAT = 0;
my $totalATbases = 0;
my $highATclones = 0;

my $totalpolyA = 0;
my $totalpolyAbases = 0;
my $highpolyAclones = 0;

my $totalpolyC = 0;
my $totalpolyCbases = 0;
my $highpolyCclones = 0;

my $totalpolyG = 0;
my $totalpolyGbases = 0;
my $highpolyGclones = 0;

my $totalpolyT = 0;
my $totalpolyTbases = 0;
my $highpolyTclones = 0;

my $clones = Clones->new( plate_id=>[$plate_id] );

$clones->add_finishing_info( sequence=>1 );

foreach my $clone (keys %$clones){
    print ">$clone\n";
    #print "$clones->{$clone}{sequence}\n";
    my $sequence = $clones->{$clone}{sequence};
    #Put this sequence into a temp file so that EMBOSS can be run on it
    my $tempseq = "tempseq";
    open (TEMPSEQ,">$tempseq");
    print TEMPSEQ "$sequence";
    close(TEMPSEQ);

    if ( -s $tempseq){
    #call subroutines to determine length, percent GC, and occurence of various motifs for each clone
    my $length = RuninfoseqOnLength($tempseq);
    my $percentgc = RuninfoseqOnPgc($tempseq);
    my ($GCregioncount,$totalGCregions) = RunFuzznucOnMotif($tempseq,$GCmotif);
    my ($ATregioncount,$totalATregions) = RunFuzznucOnMotif($tempseq,$ATmotif);
    my ($polyAregioncount,$totalpolyAregions) = RunFuzznucOnMotif($tempseq,$polyAmotif);
    my ($polyCregioncount,$totalpolyCregions) = RunFuzznucOnMotif($tempseq,$polyCmotif);
    my ($polyGregioncount,$totalpolyGregions) = RunFuzznucOnMotif($tempseq,$polyGmotif);
    my ($polyTregioncount,$totalpolyTregions) = RunFuzznucOnMotif($tempseq,$polyTmotif);

    #Keep a tally of totals so that general averages can be calculated for the plate
    #
    #
    $clonecount++;
    $grandlength = $grandlength + $length;
    $totalpgc = $totalpgc + $percentgc;
    if ($percentgc>55){
      $highPGCclones++;
    }
    $totalGC = $totalGC + $GCregioncount;
    $totalGCbases = $totalGCbases + $totalGCregions;
    if ($GCregioncount>1 or $totalGCregions>20){
      $highGCclones++;
    }
    $totalAT = $totalAT + $ATregioncount;
    $totalATbases = $totalATbases + $totalATregions;
    if ($ATregioncount>0){
      $highATclones++;
    }
    $totalpolyA = $totalpolyA + $polyAregioncount;
    $totalpolyAbases = $totalpolyAbases + $totalpolyAregions;
    if ($polyAregioncount>1 or $totalpolyAregions>20){
      $highpolyAclones++;
    }
    $totalpolyC = $totalpolyC + $polyCregioncount;
    $totalpolyCbases = $totalpolyCbases + $totalpolyCregions;
    if ($polyCregioncount>0){
      $highpolyCclones++;
    }
    $totalpolyG = $totalpolyG + $polyGregioncount;
    $totalpolyGbases = $totalpolyGbases + $totalpolyGregions;
    if ($polyGregioncount>0){
      $highpolyGclones++;
    }
    $totalpolyT = $totalpolyT + $polyTregioncount;
    $totalpolyTbases = $totalpolyTbases + $totalpolyTregions;
    if ($polyTregioncount>0){
      $highpolyTclones++;
    }
    #Print statements for testing script
    #
    #print "\nClone tally: ","\n",$clonecount;
    #print "\nLength \= ","\n",$length;
    #print "\nGrand length tally: ","\n",$grandlength;
    #print "\nPercent GC \= ","\n",$percentgc;
    #print "\nNumber of GC rich regions = ","\n",$GCregioncount;
    #print "\nTotal number of bases in GC rich regions = ","\n",$totalGCregions;
    #print "\nNumber of AT rich regions = ","\n",$ATregioncount;
    #print "\nTotal number of bases in AT rich regions = ","\n",$totalATregions;
    #print "\nNumber of polyA regions = ","\n",$polyAregioncount;
    #print "\nTotal number of bases in polyA regions = ","\n",$totalpolyAregions;
    #print "\nNumber of polyC regions = ","\n",$polyCregioncount;
    #print "\nTotal number of bases in polyC regions = ","\n",$totalpolyCregions;
    #print "\nNumber of polyG regions = ","\n",$polyGregioncount;
    #print "\nTotal number of bases in polyG regions = ","\n",$totalpolyGregions;
    #print "\nNumber of polyT regions = ","\n",$polyTregioncount;
    #print "\nTotal number of bases in polyT regions = ","\n",$totalpolyTregions;
    print "\n-------------------------\n";
  }else{
    print "\n$clone has no sequence to analyze!!!!!!!\n";
    print "\n-------------------------\n";
  }
unlink "tempseq";
}

#Overall statistics for Plate

my $meanlength = $grandlength/$clonecount;
my $meanpgc = $totalpgc/$clonecount;
my $meanGC = $totalGC/$clonecount;
my $meanGCbases = $totalGCbases/$clonecount;
my $meanAT = $totalAT/$clonecount;
my $meanATbases = $totalATbases/$clonecount;
my $meanpolyA = $totalpolyA/$clonecount;
my $meanpolyAbases = $totalpolyAbases/$clonecount;
my $meanpolyC = $totalpolyC/$clonecount;
my $meanpolyCbases = $totalpolyCbases/$clonecount;
my $meanpolyG = $totalpolyG/$clonecount;
my $meanpolyGbases = $totalpolyGbases/$clonecount;
my $meanpolyT = $totalpolyT/$clonecount;
my $meanpolyTbases = $totalpolyTbases/$clonecount;

print OUTPUTFILE "\n>>Total Clones:\n>$clonecount";
print OUTPUTFILE "\n>>Average Clone Length:";
printf OUTPUTFILE "\n>%5.1f",$meanlength;
print OUTPUTFILE "\n>>Average percent GC:";
printf OUTPUTFILE "\n>%4.2f",$meanpgc;
print OUTPUTFILE "\n>>Number of Clones with \%\GC > 55";
printf OUTPUTFILE "\n>%4.2f",$highPGCclones;
#print OUTPUTFILE "\n>>Average number of GC rich regions per clone:";
#printf OUTPUTFILE "\n>%4.2f",$meanGC;
#print OUTPUTFILE "\n>>Average number of bases in GC rich regions:";
#printf OUTPUTFILE "\n>%4.2f",$meanGCbases;
print OUTPUTFILE "\n>>Number of Clones with extensive GC-rich regions";
printf OUTPUTFILE "\n>%4.2f",$highGCclones;
#print OUTPUTFILE "\n>>Average number of polyA regions per clone:";
#printf OUTPUTFILE "\n>%4.2f",$meanpolyA;
#print OUTPUTFILE "\n>>Average number of bases in polyA regions per clone:";
#printf OUTPUTFILE "\n>%4.2f",$meanpolyAbases;
print OUTPUTFILE "\n>>Number of Clones with extensive polyA regions";
printf OUTPUTFILE "\n>%4.2f",$highpolyAclones;
#print OUTPUTFILE "\n>>Average number of polyC regions per clone:";
#printf OUTPUTFILE "\n>%4.2f",$meanpolyC;
#print OUTPUTFILE "\n>>Average number of bases in polyC regions per clone:";
#printf OUTPUTFILE "\n>%4.2f",$meanpolyCbases;
print OUTPUTFILE "\n>>Number of Clones with extensive polyC regions";
printf OUTPUTFILE "\n>%4.2f",$highpolyCclones;
#print OUTPUTFILE "\n>>Average number of polyG regions per clone:";
#printf OUTPUTFILE "\n>%4.2f",$meanpolyG;
#print OUTPUTFILE "\n>>Average number of bases in polyG regions per clone:";
#printf OUTPUTFILE "\n>%4.2f",$meanpolyGbases;
print OUTPUTFILE "\n>>Number of Clones with extensive polyG regions";
printf OUTPUTFILE "\n>%4.2f",$highpolyGclones;
#print OUTPUTFILE "\n>>Average number of polyT regions per clone:";
#printf OUTPUTFILE "\n>%4.2f",$meanpolyT;
#print OUTPUTFILE "\n>>Average number of bases in polyT regions per clone:";
#printf OUTPUTFILE "\n>%4.2f",$meanpolyTbases;
print OUTPUTFILE "\n>>Number of Clones with extensive polyT regions";
printf OUTPUTFILE "\n>%4.2f",$highpolyTclones;
print "\n----------------------------------\n";

}
exit;


###################################################################
#Subroutine to run EMBOSS-infoseq to determine length of a sequence
###################################################################
sub RuninfoseqOnLength {

my $file = shift @_;

#Use EMBOSS-infoseq to determine length
my $length = `$emboss/infoseq $file -only -length`;
chomp $length;
$length =~ s/\s//g;
return $length;
}


#######################################################################
#Subroutine to run EMBOSS-infoseq to determine GC percent on a sequence
#######################################################################
sub RuninfoseqOnPgc {

my $file = shift @_;

#Use EMBOSS-infoseq to determine percent GC
my $pgc = `$emboss/infoseq $file -only -pgc`;
chomp $pgc;
$pgc =~ s/\s//g;
return $pgc;
}


####################################################################################
#Subroutine to run EMBOSS-fuzznuc to determine occurence of a motif in a sequence
####################################################################################
#


sub RunFuzznucOnMotif {

my $file = shift @_;
my $motif = shift @_;

#Use EMBOSS-fuzznuc to determine occurence of AT regions
`$emboss/fuzznuc -sequence $file -pattern $motif -mismatch 0 -rformat2 simple -outfile tempfuzz`;

my $tempfile = "tempfuzz";
open (TEMPFILE,$tempfile);

my $totalmotif = 0;
my $motifregioncount = 0;

while (<TEMPFILE>){
  my $line = $_;
  if ($line =~/^Length: /){
    $line =~ s/Length:(.*)/$1/;
    $motifregioncount++;
    $totalmotif = $totalmotif+$line;
    }
}
close TEMPFILE;
unlink "tempfuzz";
return ($motifregioncount,$totalmotif);

}

########################################################################
#Subroutine to Convert a plate name (like IRAL6) to a plate_ID (like 454)
########################################################################
sub ConvertPlateNameToPlateID {

my $platename = shift @_;
my $plateID;
if ($platename eq "IRAL6"){
  $plateID = 454;
}
if ($platename eq "IRAL8"){
  $plateID = 854;
}
if ($platename eq "IRAL9"){
  $plateID = 1844;
}
if ($platename eq "IRAL13"){
  $plateID = 3283;
}
if ($platename eq "IRAL18"){
  $plateID = 4341;
}
if ($platename eq "IRAL22"){
  $plateID = 6004;
}
if ($platename eq "IRAL23"){
  $plateID = 6005;
}
if ($platename eq "IRAL29"){
  $plateID = 8889;
}
if ($platename eq "IRAK15"){
  $plateID = 8891;
}
if ($platename eq "IRAL34"){
  $plateID = 9746;
}
if ($platename eq "IRAK38"){
  $plateID = 11431;
}
if ($platename eq "IRAL40"){
  $plateID = 12978;
}
if ($platename eq "IRAK57"){
  $plateID = 13964;
}
if ($platename eq "IRAL42"){
  $plateID = 15984;
}
if ($platename eq "IRAK67"){
  $plateID = 18682;
}
if ($platename eq "IRAK70"){
  $plateID = 21614;
}
if ($platename eq "IRAK75"){
  $plateID = 23024;
}
if ($platename eq "IRAL43"){
  $plateID = 23563;
}
if ($platename eq "IRAK76"){
  $plateID = 25547;
}
return $plateID;
}

