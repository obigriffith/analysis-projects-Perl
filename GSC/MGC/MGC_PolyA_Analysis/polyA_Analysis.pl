#!/usr/local/bin/perl -w

#use strict;
my $MGCsequencesfile = "/home/pubseq/databases/MGC_clones/MGC.sequences";
my $emboss = "/home/pubseq/BioSw/EMBOSS/020821/EMBOSS-2.5.0/emboss";
my $outputfile = "/mnt/disk1/home/obig/perl/MGC_PolyA_Analysis/MGCsummary.txt";
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
    print "nextline: $nextline";
    print TEMPSEQ $nextline;
  }
  if ($nextline =~ /.*MGC.*/){
    unshift (@MGCSEQ, $nextline);
    close TEMPSEQ;

    my ($chimericcount,$chimericlength) = FindChimericpolyA($tempseqfile);
    my ($center,$cloneid,$polyAlength,$notTrimmed) = FindpolyA($tempseqfile);

    print OUTFILE "Clone:$cloneid\n";
    print OUTFILE "SeqBy:$center\n";
    print OUTFILE "polyAtail:$polyAlength\n";
    print OUTFILE "Chimeric Warning:$chimericcount\n";
    print OUTFILE "Not Trimmed:$notTrimmed\n";
    print OUTFILE "----------------------------\n";
#    print "\nChimeric warning: $chimericcount internal polyA tail found in $cloneid with length $chimericlength SeqBy $center\n";
#    print "$polyA PolyA tail\(s\) found with length $polyAlength SeqBy $center2\n";
#    print "\n----------------------------------------------------\n";
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
my $polyAlength = 0;
my $center = 0;
my $cloneid = 0;
my $notTrimmed = 0;

#If polyA tail is not normal look for one followed by vector tag or some other stretch of bases
if ($polyAcount == 0){
  my $motif = "{A}A'(10,250)'[CGT]N'(1,50)''>'";
  `$emboss/fuzznuc -sequence $file -pattern $motif -mismatch 0 -outfile tempfuzz -rdesshow`;
  
  my $tempfile = "tempfuzz";
  open (TEMPFUZZ,$tempfile);
  while(<TEMPFUZZ>){
    my $line = $_;
    if ($line =~ /^\s+\d+\s+\d+\s+\.\s+[CTG](A+)[CTG][ACTG]+/){
      $polyAcount++;
      $notTrimmed++;
      $polyAlength = length($1);
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

#Look for a normal polyA tail
if ($polyAcount == 0){
  my $motif = "{A}A'(1,250)''>'";
  `$emboss/fuzznuc -sequence $file -pattern $motif -mismatch 0 -outfile tempfuzz -rdesshow`;
  my $tempfile = "tempfuzz";
  open (TEMPFUZZ,$tempfile);

  while (<TEMPFUZZ>){
    my $line = $_;
    if ($line =~ /^\s+\d+\s+\d+\s+\.\s+[CGT](A+)/){
      $polyAcount++;
      $polyAlength = length($1);
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

#If still no polyA tail found look for one with a single [CGT] at the end
if ($polyAcount == 0){
  my $motif = "{A}A'(10,250)'[CGT]'>'";
  `$emboss/fuzznuc -sequence $file -pattern $motif -mismatch 0 -outfile tempfuzz -rdesshow`;
  
  my $tempfile = "tempfuzz";
  open (TEMPFUZZ,$tempfile);
  while(<TEMPFUZZ>){
    my $line = $_;
    if ($line =~ /^\s+\d+\s+\d+\s+\.\s+[CTG](A+)[CTG]/){
      $polyAcount++;
      $notTrimmed++;
      $polyAlength = length($1);
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

#If still no polyA tail found just take note of sequencing centre
if ($polyAcount == 0){
  my $motif = "[ACGT]'>'";
  `$emboss/fuzznuc -sequence $file -pattern $motif -mismatch 0 -outfile tempfuzz -rdesshow`;
  
  my $tempfile = "tempfuzz";
  open (TEMPFUZZ,$tempfile);
  while(<TEMPFUZZ>){
    my $line = $_;
    if ($line =~ /^\#\s+Description:.*SeqBy:\s+(.*)/){
      $center = $1;
    }
    if ($line =~ /^\#\s+Sequence:\s+(\d+)\s+.*/){
      $cloneid = $1;
    }
  }
close TEMPFUZZ;
}
unlink "tempfuzz";
return ($center,$cloneid,$polyAlength,$notTrimmed);
}

######################################################################################
#Subroutine to find internal polyA motifs with vector tags that may indicate chimerism
######################################################################################
sub FindChimericpolyA{

my $file = shift @_;
my @motifs = ("{A}A'(10,250)'CTCGAGN'(51)'","{A}A'(10,250)'GGGCGGCCGN'(51)'","{A}A'(10,250)'[CGT][ACGT]'(1,15)'GCGGCCGCN'(51)'","{A}A'(10,250)'CTCTCCAGCGCTGGATCN'(51)'");
my $length = 0;
my $motifregioncount = 0;
my $center = 0;
my $cloneid = 0;

foreach $motif(@motifs){
  `$emboss/fuzznuc -sequence $file -pattern $motif -mismatch 0 -outfile tempfuzz -rdesshow`;

  my $tempfile = "tempfuzz";
  open (TEMPFUZZ,$tempfile);

  while (<TEMPFUZZ>){
    my $line = $_;
    if ($line =~/^\s+\d+\s+\d+\s+\.\s+[CGT](A+)[CGT][ACGT]+/){
    $length = length($1);
    $motifregioncount++;
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
unlink "tempfuzz";
return ($motifregioncount,$length);

}
