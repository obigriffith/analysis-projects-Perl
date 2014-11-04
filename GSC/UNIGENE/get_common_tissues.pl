#!/usr/local/bin/perl -w
#Determines Library name and EST size for each EST accession number of a given UNIGENE
use strict;

my $datafile = "Unigene_EST_Accessions.txt";
my $outfile = "Unigene_summary.txt";
my $libraryfile = "all_lib.txt";
my $unigene;
my $accnumber;
my $library;
my %HoH =();
my %libraryhash=();
my %HoH2=();
my %HoH3=();
my $line;
my $size;
my $tissue;
my $organ;
my $rank = 0;

#Get Unigene ID and accession numbers for all ESTs so that library ID and EST size can be determined
open (OUTFILE,">$outfile") or die "can't open $outfile";
open (DATAFILE,$datafile) or die "can't open $datafile";
while(<DATAFILE>){
  $line = $_;
  if ($line =~ /^Unigene\sID:\s(\d+)/){
    $unigene = $1;
    next;
  }
  if ($line =~ /^EST\saccession\snumber:\s(\w+)/){
    $accnumber = $1;
    print "collecting data from SRS-dbEST for Unigene:$unigene Acc number: $accnumber\n";

    ($library,$size)=getDataFromSRS($accnumber);
    
#    print "Here is the library value before loop: $library\n";
    
    ($tissue,$organ)=getTissueforLibrary($library);

    enterDataIntoHash($unigene,$accnumber,$library,$size);
    enterDataIntoHash2($unigene,$accnumber,$tissue,$library);
    enterDataIntoHash3($unigene,$accnumber,$organ,$library);
  }
}

#Print out hash containing Unigene Id's, Accession Numbers, Library Ids, and EST sizes
#print OUTFILE "Unigene:\t EST Acc:   Lib ID:   EST size:\n";
#print OUTFILE "Unigene:\tLibrary:\n";
#foreach $unigene(sort{$a<=>$b} keys %HoH){
#  foreach $library (sort keys %{ $HoH{$unigene} } ){
#    foreach $size (sort {$a<=>$b} keys %{ $HoH{$unigene}{$library} } ){
#	print OUTFILE "$unigene:  $HoH{$unigene}{$library}{$size}:  $library:  $size\n";
#    }
#  }
#}

#Print out hash containing Unigene ID's, Tissues, Library and Accession numbers
#print OUTFILE "Unigene:  Library:  Tissue\n";
#foreach $tissue(sort keys %HoH2){
#  foreach $library(sort keys %{ $HoH2{$tissue} } ) {
#    foreach $unigene (sort keys %{ $HoH2{$tissue}{$library} } ){
#      print OUTFILE "$unigene:  $library:  $tissue\n"; # $unigene:  $HoH2{$tissue}{$unigene}\n";
#    }
#  }
#}

#Print out hash containing Unigene ID's, Organ, Library and Accession numbers
my $count = 0;
print OUTFILE "Unigene:  Library:  Organ\n";
foreach $organ(sort keys %HoH3){
  print OUTFILE "ORGAN:  $organ\n";
  foreach $library(sort keys %{ $HoH3{$organ} } ) {
    $count = 0;
    $rank = FindRank($library);
    print OUTFILE "LIBRARY: $library";
    foreach $unigene (sort keys %{ $HoH3{$organ}{$library} } ){
      $count++;
#      print OUTFILE "$unigene:  $library:  $organ\n"; # $unigene:  $HoH2{$tissue}{$unigene}\n";
    }
    print OUTFILE "COUNT: $count  RANK: $rank\n";
  }
}

close DATAFILE;
close OUTFILE;
#close OUTFILE2;
exit;

sub getDataFromSRS{
#Get library name and EST sequence size from SRS-dbEST
my $tempacc = shift @_;
my $library = 0;
my $size = 0;

open(SRS,"getz '[dbest-acc:$tempacc]' -f 'lib siz seq src'|");

while (<SRS>){
  my $line = $_;
  if ($line =~ /^Lib\sName:\s+(\w+.+)/){
    $library = $1;
  }
  if ($line =~ /^[ACGTN]+/){
    $line =~ s/\s//g;
    $size = $size + length($line);
  }
}

close SRS;
return ($library,$size);
}

#################################################################
#Check what tissue the library was made from
#################################################################
sub getTissueforLibrary{
my $library = shift @_;
my $tissue = "n/a";
my $organ = "n/a";
my $linestatus = 0;
my $tissuetemp;
my $organtemp;

$library  =~ s/\s//g;
if ($library){
#  print "Library to look for tissue $library\n";
  open (LIBRARIES,$libraryfile) or die "can't open $libraryfile";
  while (<LIBRARIES>){
    my $line = $_;
#    print "Line: $line";
    if ($line =~ /^NAME:\s+(.+)\n/){
      my $libtemp = $1;
      chomp $libtemp;
      $libtemp =~ s/\s//g;
#      print "$library $libtemp\n";
      if ($library eq $libtemp){
#	print OUTFILE "found $library in the library file\n";
	$linestatus = 1;
      }
    }

    if ($line =~ /^ORGAN:\s+(.+)\s+\n/){
      $organtemp = $1;
      if ($linestatus == 1){
	$organ = $organtemp;
	$linestatus = 2;
      }
    }

    if ($line =~ /^\s+\`\-\-\-\s+TISSUE:\s+(.+)\s+\n/){
#      print "found a tissue: $line\n";
      $tissuetemp = $1;
      if ($linestatus == 2){
	$tissue = $tissuetemp;
#	print OUTFILE "Library: $library Tissue: $tissue\n";
	$linestatus = 0;
      }
    }
  }
}
close LIBRARIES;
chomp $tissue;
return($tissue,$organ);
}


#####################################################################
#Enter data into a hash
###################################################################
sub enterDataIntoHash{
#Enter data into a hash of hashes

my $unigene = shift @_;
my $accnumber = shift @_;
my $library = shift @_;
my $size = shift @_;

$HoH{$unigene}{$library}{$size}=$accnumber;

}

#####################################################################
#Enter data into a second hash
###################################################################
sub enterDataIntoHash2{
#Enter data into a hash of hashes

my $unigene = shift @_;
my $accnumber = shift @_;
my $tissue = shift @_;
my $library = shift @_;

$HoH2{$tissue}{$library}{$unigene}=$accnumber;

}

#####################################################################
#Enter data into a third hash
###################################################################
sub enterDataIntoHash3{
#Enter data into a hash of hashes

my $unigene = shift @_;
my $accnumber = shift @_;
my $organ = shift @_;
my $library = shift @_;

$HoH3{$organ}{$library}{$unigene}=$accnumber;

}

##################################################################
#Find rank in Lukas' list for each library
#################################################################
sub FindRank{
my $rankfile = "lib_rank.txt";
open (RANKFILE, $rankfile) or die "can't open $rankfile";
my $library = shift @_;
my $libID;
my $libRank;
my $rank = 0;

if ($library =~ /(\w+).+/){
  $library = $1;
}

while (<RANKFILE>){
  my $line = $_;
  if ($line =~ /^(\w+)\t+(\d+)\n$/){
    $libID = $1;
    $libRank = $2;
  }
  print "compare $library to $libID with rank $libRank\n";
  if ($libID eq $library){
    $rank = $libRank;
  }


}
close RANKFILE,
return ($rank);
}
