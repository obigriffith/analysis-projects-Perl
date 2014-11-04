#!/usr/local/bin/perl

use strict;

#/i will do case-insensitive matching

print "---------
This script reads in all TRANS*.phd.1 files in an assembly, and creates TRANS*.phd.2 files which have all polyA and polyT regions of 8 bases or more set to quality of 98.  The script should be run prior to editing/finishing PGATE assemblies, since transposon polyA and polyT sequencing is problematic in these assemblies.
---------\n";

print "Enter assembly: \n";
my $assembly = <STDIN>;
chomp($assembly);

my $dir = "/home/sequence/Projects/Human_cDNA/Assemblies/" . $assembly . "/phd_dir";
chdir($dir);

my @phdFiles = <TRANS*.phd.1>;

foreach my $phdFile(@phdFiles){

  open(WRITEFILE,">>slippage_analysis.txt");

  my @array;
  my $arrayInc = 0;
  my @blockArray;  # increment, start position, end position
  my $blockArrayInc = 0;

  #---------------------------- each TRANS*.phd.1 file
  open(PHDFILE,$phdFile);

  my $firstA = -1;
  my $startA;
  my $aInc = 0;
  my $firstT = 1;
  my $startT;
  my $tInc = 0;

  my $linestatus = 0;
  while(<PHDFILE>){

    my $line = $_;
    chomp($line);

    if($line =~ /END_DNA/){                                         #add sthg to delete files that are unchanged ?
      my $numberToBlock = $blockArrayInc;
      if($numberToBlock > 0){
	  print "$phdFile\tblocking sequences...\n";
	  print WRITEFILE ">$phdFile\n";
	for(my $i = 0; $i < $numberToBlock; $i++){
	    my $start = $blockArray[$i]{start};
	    my $end = $blockArray[$i]{end};
	     my $number_blocked = $end-$start;
	    print WRITEFILE "$i,$number_blocked\n";
	    for(my $j = ($start + 1); $j < ($end - 1); $j++){
	    $array[$j][1] = 98;  # modify seq array
	  }
     	}
      }

      for(my $i = 0; $i < $arrayInc; $i++){
	#print WRITEFILE "$array[$i][0] $array[$i][1] $array[$i][2]\n";  # print whole seq array out here
      }
      $linestatus = 0;
    }
    if($linestatus == 0){
      #print WRITEFILE "$line\n";  # if linestatus == 0, print line as is
      if($line =~ /BEGIN_DNA/){
	$linestatus = 1;
      }
      else{
	next;
      }
    }
    if($line =~ /(\w)\s(\d+)\s(\d+)/ ){
      my $base = $1;
      my $score = $2;
      my $other = $3;

      if($tInc > 7){
	if($base ne "t"){
	  $blockArray[$blockArrayInc]{start} = $startT;  # problem:  won't block poly sequence at very ends of reads
	  $blockArray[$blockArrayInc]{end} = $arrayInc;
	  $blockArrayInc++;
	}
      }
      if($aInc > 7){
	if($base ne "a"){
	  $blockArray[$blockArrayInc]{start} = $startA;
	  $blockArray[$blockArrayInc]{end} = $arrayInc;
	  $blockArrayInc++;
	}
      }

      if($base eq "a"){

	if($aInc == 0){
	  $firstA = $arrayInc;   # firstA = start of polyA tail
	}
	$tInc = 0;
	$startT = -1;
	$aInc++;
	if(($aInc > 7) && ($startA == -1)){
	  $startA = $firstA;     # startA = start of polyA tail 10 bases long
	}
      }

      elsif($base eq "t"){
	if($tInc == 0){
	  $firstT = $arrayInc;   # firstT = start of polyT tail
	}
	$tInc++;
	$aInc = 0;
	$startA = -1;
	if(($tInc > 7) && ($startT == -1)){
	  $startT = $firstT;     # startT = start of polyT tail 10 bases long
	}
      }

      else{
	$aInc = 0;
	$tInc = 0;
	$startT = -1;
	$startA = -1;
      }
      $array[$arrayInc][0] = $base;
      $array[$arrayInc][1] = $score;
      $array[$arrayInc][2] = $other;
      $arrayInc++;
    }

  }  # end of while loop

  close WRITEFILE;
}  # end of foreach loop



