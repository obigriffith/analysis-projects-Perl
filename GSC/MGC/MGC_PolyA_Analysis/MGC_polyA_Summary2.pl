#!/usr/local/bin/perl -w

#Imports summary data from analysis of MGC.sequences (found in MGCsummary.txt) into a HASH
use strict;

my $infile = "MGCsummary.txt";
#my $infile = "MGCsummaryTest.txt";
my $outfile = "MGC_polyA_summary2.txt";
my $VectorLibraryList = "VectorLibraryList.txt";
my $temp = "temp";

open (INFILE, $infile) or die "Can not open $infile";
open (OUTFILE, ">$outfile") or die "Can not open $outfile";
open (TEMP, ">$temp") or die "Can not open $temp";

my $cloneid=0;
my $SeqBy=0;
my $polyA=0;
my $chimeric=0;
my $linestatus=0;
my $notTrimmed=0;
my $vector = 0;
my $library = 0;
my %MGC = ();
my %Chimeric = ();
my %notTrimmed = ();
my %byVector = ();
my %byLibrary = ();

#For each line of the summary file parses the value into appropriate variables
while(<INFILE>){
  my $line = $_;

  if ($line =~ /^Clone:(\d+)/){
    $cloneid = $1;
    next;
  }
  if ($line =~ /^SeqBy:(.*)/){
    $SeqBy = $1;
    next;
  }
  if ($line =~ /^polyAtail:(\d+)/){
    $polyA = $1;
    next;
  }
  if ($line =~ /^Chimeric Warning:(\d+)/){
    $chimeric = $1;
    next;
  }
  if ($line =~/^Not Trimmed:(\d+)/){
    $notTrimmed = $1;
    next;
  }
  if ($line =~/^-+/){
    $linestatus = 1;
  }

#For each clone a subroutine is run to determine its vector and library ID
#Once the data set for each clone is complete the data are sent to a subroutine to be put into a hash

  if ($linestatus == 1){
    my ($vector,$library) = DetermineVectorandLibrary($cloneid);
    EnterDataIntoHash($cloneid,$SeqBy,$polyA,$chimeric,$notTrimmed,$vector,$library);
    $linestatus = 0;
    next;
  }
}

#Print out contents of "PolyA length distribution" hashes by sequencing centre
print "PolyA tail length distribution for each sequencing center:\n";
print OUTFILE ">PolyA distribution by sequencing centre:\n";
foreach $SeqBy (sort keys %MGC) {
  print "$SeqBy\n";
  print OUTFILE "$SeqBy\n";
  foreach $polyA (sort { $a <=> $b } keys %{$MGC{$SeqBy} } ) {
    print "$polyA: $MGC{$SeqBy}{$polyA}\n";
    print OUTFILE "$polyA: $MGC{$SeqBy}{$polyA}\n";
  }
}

#Print out contents of "PolyA length distribution" hashes by vector
print "PolyA tail length distribution for each vector:\n";
print OUTFILE ">PolyA distribution by vector:\n";
foreach $vector (sort keys %byVector) {
  print "$vector\n";
  print OUTFILE "$vector\n";
  foreach $polyA (sort { $a <=> $b } keys %{$byVector{$vector} } ) {
    print "$polyA: $byVector{$vector}{$polyA}\n";
    print OUTFILE "$polyA: $byVector{$vector}{$polyA}\n";
  }
}

#Print out contents of "PolyA length distribution" hashes by library
print "PolyA tail length distribution for each library:\n";
print OUTFILE ">PolyA distribution by library:\n";
foreach $library (sort keys %byLibrary) {
  print "$library\n";
  print OUTFILE "$library\n";
  foreach $polyA (sort { $a <=> $b } keys %{$byLibrary{$library} } ) {
    print "$polyA: $byLibrary{$library}{$polyA}\n";
    print OUTFILE "$polyA: $byLibrary{$library}{$polyA}\n";
  }
}
#Print out contents of "possible chimeric distribution" hashes
print "\nChimeric warnings for each center:\n";
print OUTFILE "\nChimeric warnings\n";
foreach $SeqBy (sort keys %Chimeric) {
  print "$SeqBy\n";
  print OUTFILE "$SeqBy\n";
  foreach $chimeric (sort keys %{$Chimeric{$SeqBy} } ) {
    print "$chimeric: $Chimeric{$SeqBy}{$chimeric}\n";
    print OUTFILE "$chimeric: $Chimeric{$SeqBy}{$chimeric}\n";
  }
}

#Print out contents of "Not Trimmed distribution" hashes
print "\nNot Trimmed warnings for each center:\n";
print OUTFILE "\nNot Trimmed warnings\n";
foreach $SeqBy (sort keys %notTrimmed) {
  print "$SeqBy\n";
  print OUTFILE "$SeqBy\n";
  foreach $notTrimmed (sort keys %{$notTrimmed{$SeqBy} } ) {
    print "$notTrimmed: $notTrimmed{$SeqBy}{$notTrimmed}\n";
    print OUTFILE "$notTrimmed: $notTrimmed{$SeqBy}{$notTrimmed}\n";
  }
}

close INFILE;
close TEMP;

#Compile list of Clones for Chimeric and Trim warnings
open (SUMMARY, $temp) or die "\ncan not open $temp\n";

my $clone = 0;
my $centre = 0;
my $chimer = 0;
my $trim = 0;
my @BCCRC_Chimer = ();
my @BCCRC_Trim = ();
my @Baylor_Chimer = ();
my @Baylor_Trim = ();
my @ISB_Chimer = ();
my @ISB_Trim = ();
my @NISC_Chimer = ();
my @NISC_Trim = ();
my @Stanford_Chimer = ();
my @Stanford_Trim = ();

while (<SUMMARY>){
  my $line = $_;
  if ($line =~ /^Clone:(\d+)\s+SeqBy:(.*)PolyA:\d+\s+Chimeric:(\d+)\s+.*:(\d)/){
    $clone = $1;
    $centre = $2;
    $chimer = $3;
    $trim = $4;
  }
  if ($centre =~ /^Baylor.*/){
    if ($chimer > 0){
      push (@Baylor_Chimer, $clone);
    }
    if ($trim > 0){
      push (@Baylor_Trim, $clone);
    }
  }
  if ($centre =~ /^British.*/){
    if ($chimer > 0){
      push (@BCCRC_Chimer, $clone);
    }
    if ($trim > 0){
      push (@BCCRC_Trim, $clone);
    }
  }
  if ($centre =~ /^Institute.*/){
    if ($chimer > 0){
      push (@ISB_Chimer, $clone);
    }
    if ($trim > 0){
      push (@ISB_Trim, $clone);
    }
  }
  if ($centre =~ /^NISC.*/){
    if ($chimer > 0){
      push (@NISC_Chimer, $clone);
    }
    if ($trim > 0){
      push (@NISC_Trim, $clone);
    }
  }
  if ($centre =~ /^Stanford.*/){
    if ($chimer > 0){
      push (@Stanford_Chimer, $clone);
    }
    if ($trim > 0){
      push (@Stanford_Trim, $clone);
    }
  }
}
print OUTFILE "\nBaylor Chimeric clones: @Baylor_Chimer\n";
print OUTFILE "\nBaylor Not Trimmed Clones:  @Baylor_Trim\n";
print OUTFILE "\nBCCRC Chimeric clones: @BCCRC_Chimer\n";
print OUTFILE "\nBCCRC Not Trimmed Clones:  @BCCRC_Trim\n";
print OUTFILE "\nISB Chimeric clones: @ISB_Chimer\n";
print OUTFILE "\nISB Not Trimmed Clones:  @ISB_Trim\n";
print OUTFILE "\nNISC Chimeric clones: @NISC_Chimer\n";
print OUTFILE "\nNISC Not Trimmed Clones:  @NISC_Trim\n";
print OUTFILE "\nStanford Chimeric clones: @Stanford_Chimer\n";
print OUTFILE "\nStanford Not Trimmed Clones:  @Stanford_Trim\n";

close SUMMARY;
close OUTFILE;
unlink "temp";
exit;

#####################################################################
#Keep tally of each polyA length and chimeric warning for each center
#####################################################################
sub EnterDataIntoHash{
my $cloneid = shift @_;
my $SeqBy = shift @_;
my $polyA = shift @_;
my $chimeric = shift @_;
my $notTrimmed = shift @_;
my $vector = shift @_;
my $library = shift@_;

print "Clone:$cloneid  SeqBy:$SeqBy  PolyA:$polyA  Chimeric:$chimeric  Not Trimmed:$notTrimmed  Vector:$vector  Library:$library\n";
print TEMP "Clone:$cloneid  SeqBy:$SeqBy  PolyA:$polyA  Chimeric:$chimeric  Not Trimmed:$notTrimmed\n";

$MGC{$SeqBy}{$polyA}++;
$Chimeric{$SeqBy}{$chimeric}++;
$notTrimmed{$SeqBy}{$notTrimmed}++;
$byVector{$vector}{$polyA}++;
$byLibrary{$library}{$polyA}++;
return ();

}

######################################################################
#Determine Vector and Library for each clone
######################################################################
sub DetermineVectorandLibrary{
my $cloneid = shift @_;
my $clone = 0;
my $vector = 0;
my $library = 0;
open (VECTORLIBRARY, $VectorLibraryList) or die "Can not open $VectorLibraryList";
foreach my $line(<VECTORLIBRARY>){
  if ($line =~ /^\d+\s+$cloneid\s+(\w+|\w+-\w+)\s+(\d+).*$/){
    $vector = $1;
    $library = $2;
  }
}

close VECTORLIBRARY;
return ($vector, $library);
}
