#!/usr/bin/perl -w

use strict;
use Data::Dumper;
use Getopt::Std;

getopts("f:m:d:pgc");
use vars qw($opt_f $opt_m $opt_d $opt_p $opt_g $opt_c);

my @data;
my %sectormap;
my %markerscores;
my %finalmarkerscores;
my $marker;
my $sectormapfile = $opt_m;
my @scoresheets;
my $dir;

unless ($opt_m && ($opt_f || $opt_d)){
print "You must supply a sectormap file and a scoresheet file or folder of scoresheet files.
If phenopath data are present in folder, include -p flag.
If you would like to group scores, include -g flag.
If you would like to remove common extraneous words from marker names (e.g., new, Malignant, Benign, Phenopath) use -c flag.
Usage: deconvoluter.pl -m sectormap.txt -d ~/scoresheetfiles/ -p -g -c\n";
exit;
}

#If a single file is specified, read in the sheet
if ($opt_f){
 my $scoresheet = $opt_f;
 push (@scoresheets, $scoresheet);
}

#If a directory is specified, get a list of all sheets to be read in
if ($opt_d){
opendir(DIR, $opt_d) || die "can't opendir $opt_d: $!";
$dir=$opt_d;
@scoresheets = readdir(DIR);
}

#Get each text file and clean up names if desired
foreach my $scoresheet (@scoresheets){
  if ($scoresheet=~/(.+)\.txt/){
    $marker=$1;
  }else{
    #print "expecting file with extension .txt\n";
    next;
  }

  #clean up marker names if desired
  if ($opt_c){
    $marker=~s/_Malignant//;
    $marker=~s/_Benign//;
    $marker=~s/_NewMalignant//;
    $marker=~s/_NewBenign//;
    $marker=~s/_Phenopath//;
    $marker=~s/_ATC//;
    #$marker=~s/new//;
  }

  #Read in score sheet for the marker of interest
  my $scoresheetfile="$dir/"."$scoresheet";
  open (SCORESHEET, $scoresheetfile) or die "can't open $scoresheetfile\n";
  my $row = 0;
  while (<SCORESHEET>){
    chomp;
    my @entries = split ("\t", $_);
    my $col=0;
    foreach my $entry (@entries){
      if ($opt_p){ #For some Phenopath sheets, the data was entered with two values per cell (one for score and one for case number)
	if ($entry=~/(\S+)\s+(\S+)/){
	  $entry=$1; #keep only the score value.
	}
      }
      $data[$col][$row]=$entry;
      $col++;
    }
    $row++;
  }
  close SCORESHEET;

  #Read in sector map which identifies coordinates in score sheet that correspond to each case
  #Note, often the cases are in duplicate on the array
  my $entry=1;
  open (SECTORMAP, $sectormapfile) or die "can't open $sectormapfile\n";
  my $firstline=<SECTORMAP>;
  while (<SECTORMAP>){
    chomp;
    my @line = split ("\t", $_);
    my $case=$line[0];
    my $x_coord=$line[1];
    my $y_coord=$line[2];
    $sectormap{$entry}{$case}{'x'}=$x_coord;
    $sectormap{$entry}{$case}{'y'}=$y_coord;
    $entry++;
  }
  close SECTORMAP;
  #Based on sector map, get scores from scoresheet for each case
  #print "entry\tcase\tx\ty\tscore\n";
  foreach my $entry (sort{$a<=>$b} keys %sectormap){
    foreach my $case (sort{$a<=>$b} keys %{$sectormap{$entry}}){
      my $x_coord=$sectormap{$entry}{$case}{'x'};
      my $y_coord=$sectormap{$entry}{$case}{'y'};
      my $score = $data[$x_coord][$y_coord];
#      print "x=$x_coord, y=$y_coord\n";
      unless ($score=~/\S+/){print "score '$score' for $scoresheet empty\n";}
      unless ($score=~/\d+/){$score=-1;} #If score is not a number set to -1
      $markerscores{$marker}{$case}{$entry}=$score;
      #print "$marker\t$entry\t$case\t$x_coord\t$y_coord\t$score\n";
    }
  }
  #print Dumper (@data);

  foreach my $marker (keys %markerscores){
    foreach my $case (keys %{$markerscores{$marker}}){
      my $maxscore=-1; #Assume no valid score
      foreach my $entry (keys %{$markerscores{$marker}{$case}}){
	my $score = $markerscores{$marker}{$case}{$entry};
	if ($score>$maxscore){$maxscore=$score;} #If score is greater than -1 or previous entry make it the new maxscore
      }
      if ($maxscore==-1){$maxscore='NA';} #If no score greater than -1, set score to 'NA'.
      $finalmarkerscores{$case}{'g0'}{$marker}=$maxscore; #Just take max score for final marker scores.
    }
  }
}

#Perform score groupings if requested
#Two basic groupings are performed as well as leaving ungrouped data alone:
#Ungrouped (g0): 0,1,2,3,4...
#Grouping #1 (g1): 0 vs 1+
#Grouping #2 (g2): 0,1 vs 2+

if ($opt_g){
  foreach my $case (keys %finalmarkerscores){
    foreach my $marker (keys %{$finalmarkerscores{$case}{'g0'}}){
      my ($score_g1, $score_g2);
      my $score_ungrouped = $finalmarkerscores{$case}{'g0'}{$marker};
      my $marker_g1 = "$marker"."_g1";
      my $marker_g2 = "$marker"."_g2";
      #If score is missing then just leave it as is
      if ($score_ungrouped eq 'NA'){
	$finalmarkerscores{$case}{'g1'}{$marker_g1}='NA';
	$finalmarkerscores{$case}{'g2'}{$marker_g2}='NA';
	next;
      }
      #Assign grouped score for grouping #1
      if ($score_ungrouped==0){
	$score_g1=0;
      }elsif($score_ungrouped>0){
	$score_g1=1;
      }else{
	$score_g1='NA';
      }
      #Assign grouped score for grouping #2
      if ($score_ungrouped<2){
	$score_g2=0;
      }elsif($score_ungrouped>=2){
	$score_g2=1;
      }else{
	$score_g2='NA';
      }
      #Finally, add these grouped scores to the Finalmarkerscore hash
      $finalmarkerscores{$case}{'g1'}{$marker_g1}=$score_g1;
      $finalmarkerscores{$case}{'g2'}{$marker_g2}=$score_g2;
    }
  }
}
#print Dumper (%finalmarkerscores);

#Print marker names for all markers and groupings (use case '1' to access hash, all cases should have same markers)
my @markerlist;
foreach my $grouping (sort{$a cmp $b} keys %{$finalmarkerscores{1}}){
  foreach my $marker (sort{$a cmp $b} keys %{$finalmarkerscores{1}{$grouping}}){
    push (@markerlist, $marker);
  }
}
print "Case\t",join("\t", @markerlist),"\n";

#Print ungrouped (and grouped) scores for all cases/markers.
foreach my $case (sort{$a <=> $b} keys %finalmarkerscores){
  print "$case";
  foreach my $grouping (sort{$a cmp $b} keys %{$finalmarkerscores{$case}}){
    foreach my $marker (sort{$a cmp $b} keys %{$finalmarkerscores{$case}{$grouping}}){
      print "\t$finalmarkerscores{$case}{$grouping}{$marker}";
    }
  }
  print "\n";
}
