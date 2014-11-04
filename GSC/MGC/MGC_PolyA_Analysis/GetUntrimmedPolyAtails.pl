#!/usr/local/bin/perl -w

#use strict;
#my $MGCsequencesfile = "testseq";
my $MGCsequencesfile = "/home/pubseq/databases/MGC_clones/MGC.sequences";
my $emboss = "/home/pubseq/BioSw/EMBOSS/020821/EMBOSS-2.5.0/emboss";
my $outputfile = "/mnt/disk1/home/obig/perl/MGC_PolyA_Analysis/Untrimmedsummary.txt";
my $tempseqfile = "tempseq";

open (OUTFILE,">$outputfile") or die "can not open $outputfile";
open (MGCSEQ,$MGCsequencesfile) or die "can not open $MGCsequencesfile";

my @MGCSEQ = <MGCSEQ>;

#Add a ghost >MGC to end of array so that program doesn't skip last clone
my $ghostMGC = ">MGC";
push (@MGCSEQ, $ghostMGC);

while (@MGCSEQ){

my $nextline;
my $firstline = shift @MGCSEQ;
print "firstline: $firstline";

open (TEMPSEQ, ">$tempseqfile") or die "can not open $tempseqfile";
print TEMPSEQ $firstline;

while (@MGCSEQ){
  $nextline = shift @MGCSEQ;
  unless ($nextline =~ /.*MGC.*/){
#    print "nextline: $nextline";
    print TEMPSEQ $nextline;
  }
  if ($nextline =~ /.*MGC.*/){
    unshift (@MGCSEQ, $nextline);
    close TEMPSEQ;

    my ($center,$cloneid,$notTrimmed,$sequence) = FindpolyA($tempseqfile);
    if ($notTrimmed > 0){
      print OUTFILE "Clone:$cloneid\n";
      print OUTFILE "SeqBy:$center\n";
     #print "Not Trimmed:$notTrimmed\n";
      print OUTFILE "polyA tail sequence:$sequence\n";
      print OUTFILE "----------------------------\n";
    }
    last;
  }
}
}
close OUTFILE;
exit;

############################################################################
#Subroutine to determine presence and length of polyA tail
############################################################################
sub FindpolyA{
my $file = shift @_;
my $polyAcount = 0;
my $center = 0;
my $cloneid = 0;
my $notTrimmedcount = 0;
my $nottrimmedpolyA = 0;

#Look for a polyA tail followed by vector tag or some other stretch of bases
if ($polyAcount == 0){
  my $motif = "{A}A'(10,250)'[CGT]N'(1,50)''>'";
  `$emboss/fuzznuc -sequence $file -pattern $motif -mismatch 0 -outfile tempfuzz -rdesshow`;
  
  my $tempfile = "tempfuzz";
  open (TEMPFUZZ,$tempfile);
  while(<TEMPFUZZ>){
    my $line = $_;
    if ($line =~ /^\s+\d+\s+\d+\s+\.\s+[CTG](A+[CTG][ACTG]+)/){
      $polyAcount++;
      $notTrimmedcount++;
      $nottrimmedpolyA = $1;
    }
    if ($line =~ /^\#\s+Description:.*SeqBy:\s+(.*)/){
      $center = $1;
    }
    if ($line =~ /^\#\s+Sequence:\s+(\d+)\s+.*/){
      $cloneid = $1;
    }
  }
close TEMPFUZZ;
}

#Look for a polyA tail with a single [CGT] at the end
if ($polyAcount == 0){
  my $motif = "{A}A'(10,250)'[CGT]'>'";
  `$emboss/fuzznuc -sequence $file -pattern $motif -mismatch 0 -outfile tempfuzz -rdesshow`;
  
  my $tempfile = "tempfuzz";
  open (TEMPFUZZ,$tempfile);
  while(<TEMPFUZZ>){
    my $line = $_;
    if ($line =~ /^\s+\d+\s+\d+\s+\.\s+[CTG](A+[CTG])/){
      $polyAcount++;
      $notTrimmedcount++;
      $nottrimmedpolyA = $1;
    }
    if ($line =~ /^\#\s+Description:.*SeqBy:\s+(.*)/){
      $center = $1;
    }
    if ($line =~ /^\#\s+Sequence:\s+(\d+)\s+.*/){
      $cloneid = $1;
    }
  }
close TEMPFUZZ;
}
#unlink "tempfuzz";
return ($center,$cloneid,$notTrimmedcount,$nottrimmedpolyA);

}
