#!/usr/local/bin/perl -w
#Determines Library name and EST size for each EST accession number of a given UNIGENE
use strict;

my $datafile = "Unigene_EST_Accessions.txt";
my $outfile = "Unigene_summary.txt";
my $outfile2 = "commonlibraries.txt";
#my $tempacc = "R61384";
my $unigene;
my $accnumber;
my $library;
my %HoH =();
my %libraryhash=();
my $line;
my $size;

#Get Unigene ID and accession numbers for all ESTs so that library ID and EST size can be determined
open (OUTFILE,">$outfile") or die "can't open $outfile";
open (OUTFILE2,">$outfile2") or die "can't open $outfile2";
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
    enterDataIntoHash($unigene,$accnumber,$library,$size);
  }
}

#Print out hash containing Unigene Id's, Accession Numbers, Library Ids, and EST sizes
my $max = 0;
my $nextmax =0;
my $nextnextmax = 0;
my $fourthmax = 0;
my $fifthmax = 0;
my $maxlibrary = 0;
my $nextmaxlibrary = 0;
my $nextnextmaxlibrary = 0;
my $fourthmaxlibrary = 0;
my $fifthmaxlibrary = 0;

#print OUTFILE "Unigene:\t EST Acc:   Lib ID:   EST size:\n";
print OUTFILE "Unigene:\tLibrary:\n";
foreach $unigene(sort{$a<=>$b} keys %HoH){
  $max = 0;
  $nextmax = 0;
  $nextnextmax = 0;
  $fourthmax = 0;
  $fifthmax =0;
  $maxlibrary = 0;
  $nextmaxlibrary = 0;
  $nextnextmaxlibrary = 0;
  $fourthmaxlibrary = 0;
  $fifthmaxlibrary = 0;

  foreach $library (sort keys %{ $HoH{$unigene} } ){
    foreach $size (sort {$a<=>$b} keys %{ $HoH{$unigene}{$library} } ){
      if ($max < $size){

      $fifthmax = $fourthmax;
      $fourthmax = $nextnextmax;
      $nextnextmax = $nextmax;
      $nextmax = $max;
      $max = $size;
      $fifthmaxlibrary = $fourthmaxlibrary;
      $fourthmaxlibrary = $nextnextmaxlibrary;
      $nextnextmaxlibrary = $nextmaxlibrary;
      $nextmaxlibrary = $maxlibrary;
      $maxlibrary = $library;

    }
#      print OUTFILE "$HoH{$unigene}{$library}{$size}:  $library:  $size\n";
    }
#    print OUTFILE "$HoH{$unigene}{$library}{$max}:  $library:  $max\n";
  }
#  print OUTFILE "$unigene:\t\t$HoH{$unigene}{$maxlibrary}{$max}:  $maxlibrary:  $max\n";
#  print OUTFILE "$unigene:\t\t$HoH{$unigene}{$nextmaxlibrary}{$nextmax}:  $nextmaxlibrary:  $nextmax\n";
#  print OUTFILE "$unigene:\t\t$HoH{$unigene}{$nextnextmaxlibrary}{$nextnextmax}:  $nextnextmaxlibrary:  $nextnextmax\n";
  print OUTFILE "$unigene\t\t$maxlibrary\n";
  $libraryhash{$maxlibrary}{$unigene} = 1;
  print OUTFILE "$unigene\t\t$nextmaxlibrary\n";
  $libraryhash{$nextmaxlibrary}{$unigene} = 1;
  print OUTFILE "$unigene\t\t$nextnextmaxlibrary\n";
  $libraryhash{$nextnextmaxlibrary}{$unigene} = 1;
  print OUTFILE "$unigene\t\t$fourthmaxlibrary\n";
  $libraryhash{$fourthmaxlibrary}{$unigene} = 1;
  print OUTFILE "$unigene\t\t$fifthmaxlibrary\n";
  $libraryhash{$fifthmaxlibrary}{$unigene} = 1;

}

#Print out summary of unigenes organized by library for three most common libraries of each unigene
my $lib;
my $uni;
my $libsize = 0;
print OUTFILE2 "Unigene:\tLibrary\n";
  foreach $lib(sort keys %libraryhash){
  foreach $uni(sort keys %{$libraryhash{$lib} } ){
    print OUTFILE2 "$uni:\t\t$lib\n";
  }
}

#Print just libraries and number of unigenes
foreach $lib(sort keys %libraryhash){
  $libsize += scalar keys %{$libraryhash{$lib} };
  print OUTFILE2 "$lib: $libsize\n";
  print OUTFILE2 "\t\( ";
  foreach $uni(sort{$a<=>$b} keys %{$libraryhash{$lib} } ){
    print OUTFILE2 "$uni ";
  }
  print OUTFILE2 "\)\n";
  $libsize = 0;
}

close DATAFILE;
close OUTFILE;
close OUTFILE2;
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


sub enterDataIntoHash{
#Enter data into a hash of hashes
my $unigene = shift @_;
my $accnumber = shift @_;
my $library = shift @_;
my $size = shift @_;

$HoH{$unigene}{$library}{$size}=$accnumber;

}

