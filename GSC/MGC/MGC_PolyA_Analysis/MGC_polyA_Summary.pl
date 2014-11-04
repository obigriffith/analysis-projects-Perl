#!/usr/local/bin/perl -w

#Imports summary data from analysis of MGC.sequences (found in MGCsummary.txt) into a HASH
use strict;
use GD::Graph::lines;
use GD::Graph::bars;

my $infile = "MGCsummary.txt";
my $outfile = "MGC_polyA_summary.txt";
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
my %MGC = ();
my %Chimeric = ();
my %notTrimmed = ();

#For each line of the summary file parses the values into appropriate variables
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

#Once the data set for each clone is complete the data are sent to a subroutine to be put into a hash
  if ($linestatus == 1){
    EnterDataIntoHash($cloneid,$SeqBy,$polyA,$chimeric,$notTrimmed);
    $linestatus = 0;
    next;
  }
}

#Print out contents of "PolyA length distribution" hashes
print "PolyA tail length distribution for each sequencing center:\n";
print OUTFILE ">PolyA distribution:\n";
foreach $SeqBy (sort keys %MGC) {
  print "$SeqBy\n";
  print OUTFILE "$SeqBy\n";
  foreach $polyA (sort { $a <=> $b } keys %{$MGC{$SeqBy} } ) {
    print "$polyA: $MGC{$SeqBy}{$polyA}\n";
    print OUTFILE "$polyA: $MGC{$SeqBy}{$polyA}\n";
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

#Graph chimeric results
my @Baylor = ();
my @BCCRC = ();
my @ISB = ();
my @NISC =();
my @Stanford = ();

foreach $chimeric (sort keys %{$Chimeric{"Baylor Human Genome Sequencing Center"} } ) {
  my $Baylor = $Chimeric{"Baylor Human Genome Sequencing Center"}{$chimeric};
  push (@Baylor, $Baylor);
}
foreach $chimeric (sort keys %{$Chimeric{"British Columbia Cancer Research Center"} } ) {
  my $BCCRC = $Chimeric{"British Columbia Cancer Research Center"}{$chimeric};
  push (@BCCRC, $BCCRC);
}
foreach $chimeric (sort keys %{$Chimeric{"Institute for Systems Biology"} } ) {
  my $ISB = $Chimeric{"Institute for Systems Biology"}{$chimeric};
  push (@ISB, $ISB);
}
foreach $chimeric (sort keys %{$Chimeric{"NISC"} } ) {
  my $NISC = $Chimeric{"NISC"}{$chimeric};
  push (@NISC, $NISC);
}
foreach $chimeric (sort keys %{$Chimeric{"Stanford Human Genome Center"} } ) {
  my $Stanford = $Chimeric{"Stanford Human Genome Center"}{$chimeric};
  push (@Stanford, $Stanford);
}
my @legend_keys = ("Baylor","BCCRC","ISB","NISC","Stanford");
#print "\nGraph data\n";
#print "@legend_keys";


my @data = (
	    [0,1,2],
	    [@Baylor],
	    [@BCCRC],
	    [@ISB],
	    [@NISC]
	    );
#[@Stanford]
#	   );

my $graph = GD::Graph::bars->new(400,300);

  $graph->set( 
      x_label           => 'X Label',
      y_label           => 'Y label',
      title             => 'Some simple graph',
      y_max_value       => 100,
      y_tick_number     => 10,
      y_label_skip      => 2 
  );

$graph->set_legend(@legend_keys);
my $gd = $graph->plot(\@data);

  open(IMG, '>file.gif') or die $!;
  binmode IMG;
  print IMG $gd->gif;
  close IMG;

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
print "Clone:$cloneid  SeqBy:$SeqBy  PolyA:$polyA  Chimeric:$chimeric  Not Trimmed:$notTrimmed\n";
print TEMP "Clone:$cloneid  SeqBy:$SeqBy  PolyA:$polyA  Chimeric:$chimeric  Not Trimmed:$notTrimmed\n";

$MGC{$SeqBy}{$polyA}++;
$Chimeric{$SeqBy}{$chimeric}++;
$notTrimmed{$SeqBy}{$notTrimmed}++;
return ();

}
