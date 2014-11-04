#!/usr/local/bin/perl -w
################################################################################################
#Takes an MGC submission file as input.  Converts it to fasta format and removes phred values
#Sets up a BLAT server of genome using gfServer and queries it with clones sequences using gfClient
#currently only mouse and human genomes are available
#Calculates percent identities and summarizes BLAT output for analysis
#
#################################################################################################
use strict;
#golden_path Genome directories.  If you add more make sure to add an option for the new genome
#in the queryBlatServer subroutine
#my $humandir = "/home/obig/perl/BLAT/golden_path_temp/*.nib";
my $humandir = "/home/pubseq/databases/H_sapiens_genome/golden_path/*.nib";
my $mousedir = "/home/pubseq/databases/M_musculus_genome/golden_path/*.nib";
my $genomedir;
my @scores = ();

#print documentation and make sure the user knows what he/she is getting into
printdocumentation();
print "proceed \(y\)? ";
my $answer = <STDIN>;
chomp $answer;
unless($answer eq 'y'){
  exit;
}

#Convert submission file to fasta format and remove all phred qualities
my $tempfile;
print "enter name of submission file to check for chimerism:\n";
my $file = <STDIN>;
chomp $file;
getMGCfastaSequences($file);


#Setup Blat server and query with sequences from submission file
my $blatfile;
print "Enter node you are logged into \(eg. 6of3\): ";
my $node=<STDIN>;
chomp $node;
queryBlatServer();

#Parse results from blat into array
my $summaryfile = $file;
$summaryfile =~ s/\.txt/\_summary\.txt/;
parseBlatResults();


#Analyze results for chimerism
#not done yet
#this still needs to be developed

checkForChimerism();



#Exit kill gfServer, delete temp files, exit
unlink $tempfile;
killServerAndExit();
exit;

################################################################################
#getMGCfastaSequences
#Converts GSC_MGCsubmission file to fasta format and removes all phred qualities
################################################################################
sub getMGCfastaSequences{

use strict;
my $submissionID;
my $dir = "/mnt/disk7/MGC/submissions/";
my $submissionfile = shift @_;
my $filepath = "$dir" . "$submissionfile";

open(SUBMISSION,$filepath) or die ">Can't open $filepath";

if ($submissionfile =~ /(.+)\.txt/){
  $submissionID = $1;
}else{
  print "Submission file should be in .txt format\n";
}

$tempfile = $submissionID . ".fasta";
open(TEMPFILE,">$tempfile");
my @array = <SUBMISSION>;
foreach my $line(@array){
	if ($line =~ /^(MGC:)\s(\d+)$/){
	print TEMPFILE ">".$1.$2,"\n";
	next;
	}
	if ($line =~ /^[ACGT]/){
	print TEMPFILE $line;
	next;
	}
}
print "\n$submissionfile converted to fasta format in $tempfile\n\n";

close SUBMISSION;
close TEMPFILE;
return ();
}

######################################################################################################
#queryBlatServer
#This script sets up a BLAT server for an entire genome.  Currently only Human and Mouse are available.
######################################################################################################
sub queryBlatServer{

use strict;

print "BLAT against human or mouse genome \(h or m\)?\n";
my $answer2 = <STDIN>;
chomp $answer2;
if ($answer2 eq 'h'){
  $genomedir = $humandir;
}elsif ($answer2 eq 'm'){
  $genomedir = $mousedir;
}else{
  print "Invalid selection\n";
  exit;
}

#Start the Blat gfServer
my $command = "gfServer start $node 8051 $genomedir";
print "Setting up server.  Please wait...\n";
print "If very slow \(> 5-10min\), kill script and try another node.\n\n";
open(BLAT, "| $command");

#Check status periodically to determine when server is ready for queries.
while(1) {
  my $status = `gfServer status $node 8051 2>/dev/null`;
  last if ($status);
  sleep 5;
}

#Query the gfServer with gfClient
$blatfile = $tempfile;
$blatfile =~ s/\.fasta/\.blat/;
print "running gfClient to query server.  PLease wait...\n";
my $query = "gfClient $node 8051 / $tempfile $blatfile";
system($query);
print "Blat complete\n";
return;
}

#################################################################################################################
#parseBlatResults
#parses the blat output file into an array, generating score and identitiy value and print summary to output file
################################################################################################################
sub parseBlatResults{
open(FILE, $blatfile);
open(OUTFILE,">$summaryfile");

my $linestatus = 0;

my @scoreArray;
my $scoreArrayIncrement = 0;

while(<FILE>){

  my $match;
  my $mismatch;
  my $qGapCount;
  my $qGapBases;
  my $tGapCount;
  my $mgc;
  my $qStart;
  my $qEnd;
  my $chrom;
  my $qSize;

  if($linestatus == 0){
    if(/-----/){
      $linestatus = 1;
    }
    next;
  }
  if(/^(\d+)\s+(\d+)\s+\d+\s+\d+\s+(\d+)\s+(\d+)\s+(\d+)\s+\d+\s+\S\s+(\S+)\s+(\d+)\s+(\d+)\s+(\d+)\s+(\w+)\s/){
    $match = $1;
    $mismatch = $2;
    $qGapCount = $3;
    $qGapBases = $4;
    $tGapCount = $5;
    $mgc = $6;
    $qSize = $7;
    $qStart = $8;
    $qEnd = $9;
    $chrom = $10;
    $mgc =~ s/MGC:(\d+)/$1/;
  }

  my $blatScore = $match - $mismatch - $qGapCount - $tGapCount;
  my $identity = ($match)/($match + $mismatch + $qGapCount);

  $identity = $identity * 100;
  $identity = sprintf "%.1f",$identity;
  $chrom =~ s/chr(.+)/$1/;
  $scoreArray[$scoreArrayIncrement][0] = $mgc;
  $scoreArray[$scoreArrayIncrement][1] = $blatScore;
  $scoreArray[$scoreArrayIncrement][2] = $identity;
  $scoreArray[$scoreArrayIncrement][3] = $chrom;
  $scoreArray[$scoreArrayIncrement][4] = $qStart;
  $scoreArray[$scoreArrayIncrement][5] = $qEnd;
  $scoreArray[$scoreArrayIncrement][6] = $qSize;
  $scoreArrayIncrement++;

}

  @scores = sort {  #now sort the array so that it prints out nice and so that searches are easier
  my @a_fields = @$a[0..3];
  my @b_fields = @$b[0..3];
  $a_fields[0] <=> $b_fields[0]  # string sort on 1st field, then
    ||
      $b_fields[1] <=> $a_fields[1]  # numeric sort on 2nd field
	||
	  $b_fields[2] <=> $a_fields[2]  # numeric sort on 3rd field

} @scoreArray;

print "summarizing results of blat in $summaryfile\n";
print OUTFILE "MGC\t\tScore\t\tIdentity\tChromosome\tqStart\t\tqEnd\t\tqSize\n";

my $array_length = $#scores + 1;
my $array_width = '7';
my $i='0';
my $j='0';

for ($i=0;$i<$array_length;$i++){
  for ($j=0;$j<$array_width;$j++){
    print OUTFILE "$scores[$i][$j]\t\t";
  }
print OUTFILE "\n";
}

#Alternate method of printing array
#for my $array_ref (@scores){
#  print "\t [ @$array_ref ],\n"
#}

close FILE;
close OUTFILE;
return();
}


#####################################################################################################
#checkForChimerism
#analyses results in GSC_MGCsubmission##_summary.txt file and indicates makes of list 
#of chimeric or ambigous clones
######################################################################################################
sub checkForChimerism{
my $chimeric_clone_list = $file;
$chimeric_clone_list =~ s/\.txt/\_chimeric\.txt/;
open (CHIMERICCLONES, ">$chimeric_clone_list") or die "can't open $chimeric_clone_list";

my $i;
my $j;
my %Hash;
my %Chimericlist;
my $chimericflag;
my $array_length = $#scores + 1;

for ($i=0;$i<$array_length;$i++){  #for each row
  my $mgc = $scores[$i][0];
  my $score = $scores[$i][1];
  my $percID = $scores[$i][2];
  my $chrom = $scores[$i][3];
  my $qStart = $scores[$i][4];
  my $qEnd = $scores[$i][5];
  my $qSize = $scores[$i][6];
  my $sizeratio = ($qEnd-$qStart)/$qSize;
  my $Score_Size_ratio = $score/($qEnd-$qStart);
  my $all_info = "$mgc  "."$score  "."$percID  "."$chrom  "."$qStart  "."$qEnd  "."$qSize";

  if ($sizeratio > 0.95 and $Score_Size_ratio > 0.95){
    $chimericflag = "false";
  }else{
    $chimericflag = "true";
}

  $Hash{$mgc}{$sizeratio}{$Score_Size_ratio}=$chimericflag;
  $Chimericlist{$mgc} = "Chimeric";  # set each MGC as chimeric.  If not it will be switched below
}
print "\n";


foreach my $mgc(sort keys %Hash){
  foreach my $sizeratio (sort keys %{$Hash{$mgc}}){
    foreach my $Score_Size_ratio (sort keys %{$Hash{$mgc}{$sizeratio}}){
      print CHIMERICCLONES "$mgc:  $sizeratio:  $Score_Size_ratio:  $Hash{$mgc}{$sizeratio}{$Score_Size_ratio}\n";
      if ($Hash{$mgc}{$sizeratio}{$Score_Size_ratio} eq "false"){
	$Chimericlist{$mgc} = "Not Chimeric";
      }
    }
  }
}

foreach my $mgc(sort{$a<=>$b} keys %Chimericlist){
  print CHIMERICCLONES "$mgc:  $Chimericlist{$mgc}\n"
}

close CHIMERICCLONES;
return ();
}
######################################################################################################
#killServerandExit
#Kills gfServer processes.  Warning!  kills all user's gfServer processes
######################################################################################################
sub killServerAndExit{

my $killcommand = "gfServer stop $node 8051";
    system($killcommand);
print "gfServer stopped\n";
close BLAT;
exit;
}


####################################################################################
#Alternate method of killing gfServers.  Warning! kills all user's gfServer processes
####################################################################################
#my $pid;
#my $ps = `ps | grep gfServer`;
#my @ps = split /\n/,$ps;
#print "Attempting to kill gfServer\n";
#foreach my $line(@ps){
#  if ($line =~ /^\s+(\d+)\s+\w+.+/){
#    $pid = $1;
#    print "killing process: $line\n";
#    `kill $pid`;
#  }
#}


#################################################################################
#Prints documentation
#################################################################################
sub printdocumentation{
	print "finalChimericsCheck.pl\n";
	print "--------------------------------------------------------\n";
	print "Obi L. Griffith ( obig\@bcgsc.bc.ca )\n";
	print "This script runs a final check for chimeric clones before they are submitted\n";
	print "A BLAT server is set up using gfServer that can then be queried with gfClient\n";
	print "You must log into a node before running this script!\n";
	print "For most accurate results update genome:\n";
	print "Download latest chromFa.zip from http://genome.ucsc.edu/\n";
	print "Extract chromosome files into the golden_path directory:\n";
	print "/home/pubseq/databases/H_sapiens_genome/golden_path\n";
	print "run FatoNibOnAllFiles.pl from this directory\n";
	print "If the genome is up to date proceed with this script\n";
	print "The server will take a while to come online.\n";
	print "---------------------------------------------------------\n";
return();
}
