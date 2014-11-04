#!/usr/local/bin/perl -w

use strict;

print "---------
This script reads in all TRANS*.phd.1 files in an assembly, and lists TRANS*.phd.2 files which have had all polyA and polyT regions of 8 bases or more set to quality of 98.  It then loops through and does the same for 9,10,etc.
---------\n";
my %mgc_clones;
my @array1 = ();
my @array2 = ();
my @array3 = ();
my @array4 = ();

#specify size of region to look for and block
my @polysize = ('9');

#my @polysize = ('20','19','18','17','16','15','14','13','12','11','10','9');

print "Enter assembly: \n";
my $assembly = <STDIN>;
chomp($assembly);

my $outputfile = "$assembly" . "_slippage.txt";
open(OUTFILE, ">$outputfile") or die "Can't open $outputfile to output to!";

print OUTFILE "$assembly\n";
#For each poly size run the subroutines to get txns and then corresponding clones
foreach my $polysize(@polysize){
my $actualpolysize = $polysize + 1;
my @txnlist = GetHomopolymerTxnReads($polysize,$assembly);

print OUTFILE "----------------------------------------------\n";
print OUTFILE "polymer length = $actualpolysize\n";
print "----------------------------------------------\n";
print "polymer length = $actualpolysize\n";

my @clonelist = GetMGCforTxnList(\@txnlist);

my @primerlist = MakePrimerListforClones(\@clonelist);

#print "\nClones with polyA regions\n@clonelist\n";
#print "\nPrimers that were ordered:\n@primerlist";
#print "\n----------------------------------------------\n";

#Send the clone list and primer list to a subroutine to check it against the
#next list and remove all clones and primers that are not also included in
#the next group

my @newclonelist = GetReducedCloneList(\@clonelist);
print OUTFILE "\nClone List\n@newclonelist\n";
print OUTFILE "\n----------------------------------------------\n";

my @newprimerlist = GetReducedPrimerList(\@primerlist);
print OUTFILE "\nPrimer List\n@newprimerlist\n";
print OUTFILE "\n----------------------------------------------\n";

#Print out the transposon reads that have homopolymer of the length
#specified by the current loop iteration ($polysize).  The new list is
#formed from the list generated in txntemp.txt

my @newtxnlist = GetReducedTxnList($polysize);

}

close(OUTFILE);
exit;

###################################################################
#MakeTxnReadsLowQualityObi Subroutine
###################################################################
sub GetHomopolymerTxnReads{

use strict;

#Runs Ursula's blocking script on assembly specified for various different sizes of polyA regions

my $polysize = shift @_;
my $assembly = shift @_;

my $dir = "/home/sequence/Projects/Human_cDNA/Assemblies/" . $assembly . "/phd_dir";
chdir($dir);

my $txntempfile = "/mnt/disk1/home/obig/Slippage/txntemp.txt";
open(TXNTEMP,">$txntempfile");



my @phdFiles = <TRANS*.phd.1>;
my @txnlist = ();

foreach my $phdFile(@phdFiles){

  my $phd2File;
  if($phdFile =~ /(.*\.phd\.)1/){
    $phd2File = $1 . "2";
  }

  #open(WRITEFILE,">$phd2File");

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
#	  print "$phdFile\tblocking sequences...\n";
	  push (@txnlist, $phd2File);
	  
	for(my $i = 0; $i < $numberToBlock; $i++){
	  my $start = $blockArray[$i]{start};
	  my $end = $blockArray[$i]{end};
	  my $number_blocked = $end-$start;
	  
	  print "$phd2File\n";
	  print ">$start,$number_blocked\n";
	  print TXNTEMP "$phd2File\n";
	  print TXNTEMP ">$start,$number_blocked\n";
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
      #print "$line\n";  # if linestatus == 0, print line as is
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

      if($tInc > $polysize){
	if($base ne "t"){
	  $blockArray[$blockArrayInc]{start} = $startT;  # problem:  won't block poly sequence at very ends of reads
	  $blockArray[$blockArrayInc]{end} = $arrayInc;
	  $blockArrayInc++;
	}
      }
      if($aInc > $polysize){
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
	if(($aInc > $polysize) && ($startA == -1)){
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
	if(($tInc > $polysize) && ($startT == -1)){
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
close PHDFILE;
}  # end of inside foreach loop
close TXNTEMP;
return @txnlist;

}  # end of subroutine


#######################################################
#GetMGCforTxnList.pl Subroutine
#######################################################
sub GetMGCforTxnList{

use strict;
use lib "/home/ybutterf/perl/lib";
use cDNA::Clones;
use Data::Dumper;

my @clonelist = ();

my $txnlist = shift @_;

#Remove endlines and file extension from array of transposon reads
my $txn;
my $clone;
foreach $txn(@$txnlist){
$txn =~ s/\n//g;
$txn =~ s/\.phd\.2//g;
}

my $mgc_clones = Clones::get_MGC_from_assembled_read(@$txnlist);

#dereference the hash
my %newhash = %$mgc_clones;

# print the whole thing
 foreach my $clone ( keys %newhash ) {
   print OUTFILE "$clone: @{ $newhash{$clone} }\n";
   push (@clonelist,$clone);
#  print "$clone: ".join(",",@{ $newhash{$clone} })."\n";
 }

return @clonelist;

}


##############################################################################
#MakePrimerListforClones subroutine
#Searches a list of clones against all the primers ordered and returns an 
#array of clones from the list given which have had one or more primer ordered
##############################################################################
sub MakePrimerListforClones{

use strict;
my $primerfile = "/mnt/disk7/MGC/oligos/primer";

#print "\nThis script will determine which clones from a given list have had primers ordered";
#print "\nEnter the file containing the list of clones:  ";
#my $clonefile = <STDIN>;
#chomp $clonefile;

#print "\nEnter name of outputfile:  ";
#my $outfile = <STDIN>;
#chomp $outfile;
#open (OUTFILE, ">$outfile")or die "Can't open $outfile to output to";
#print OUTFILE $outfile,"\n";

my @primerlist = makePrimerList($primerfile);
#my @clonelist = makeCloneList($clonefile);
my $clonelist = shift @_;

#print "\n-----------PRIMER-LIST--------------\n";
#print "@primerlist";
#print "\n------------------------------------\n";

#print "\n----------CLONE-LIST---------------\n";
#print "@$clonelist";
#print OUTFILE "\nClones with PolyA regions:\n$@clonelist";
#print "\n------------------------------------\n";


my $clone;
my $primer;
my @NewClonelist = ();

foreach $clone(@$clonelist){
#  print "\nClone:  $clone";
  foreach $primer(@primerlist){
#    print "\nPrimer:  $primer";
    if ($clone == $primer){
      push (@NewClonelist, $clone);
    }
  }
}

#print "\n-----------NEW-CLONE-LIST--------------\n";
#print "@NewClonelist";
#print OUTFILE "\nClones with polyA regions for which clones were ordered:\n@NewClonelist";
#print "\n---------------------------------------\n";

#close OUTFILE;

return @NewClonelist;
}

##################################################################
#make a an array containing all the primers that have been ordered
##################################################################
sub makePrimerList{

my($primerfilename) = @_;

open (PRIMER,$primerfilename) or die "Can't open $primerfilename file";
my @primers = <PRIMER>;
close PRIMER;

my @primers2 = ();

#remove everything except for the clone numbers for which primers were ordered
foreach my $primer(@primers){
  if ($primer =~ s/^(\d+).*/$1/){
    push( @primers2, $1 );
  }
}
#print "\n-------------------------\n";
#print "@primers2";
#print "\n-------------------------\n";

return @primers2;
}

###################################################################
#make a an array containing all the clones that have polyA regions
###################################################################
sub makeCloneList{

my($clonefilename) = @_;

open (CLONES, $clonefilename) or die "Can't open $clonefilename file";
my @Clones = <CLONES>;
close CLONES;

my @Clones2 =();

foreach my $clone(@Clones){
  if ($clone =~ /\d+/){
    $clone =~ s/\s//g;
    push ( @Clones2, $clone);
  }
}

return @Clones2;
}


#################################################################
#Remove all clones from each list that are also present in the next
#clone list
#################################################################
sub GetReducedCloneList {

my $nextarray = shift @_;
my $clone1;
my $clone2;
my $position = 0;
@array1 = @$nextarray;

foreach $clone1(@array1){
  foreach $clone2(@array2){
    if ($clone1==$clone2){
      splice(@array1,$position,1,"#");
    }
  }
$position++;
}

@array2 = @$nextarray;

return @array1;

}

#################################################################
#Remove all primers from each list that are also present in the next
#clone list
#################################################################
sub GetReducedPrimerList {

my $nextarray = shift @_;
my $primer1;
my $primer2;
my $position = 0;
@array3 = @$nextarray;


foreach $primer1(@array3){
  foreach $primer2(@array4){
    if ($primer1==$primer2){
      splice(@array3,$position,1,"#");
    }
  }
$position++;
}

@array4 = @$nextarray;

return @array3;

}

#########################################################################
#looks in txntemp.txt and determines which reads have homopolymer regions
#with length of $polysize
#########################################################################
sub GetReducedTxnList {

my $txnlistfile = "/mnt/disk1/home/obig/Slippage/txntemp.txt";
my $polysize = shift @_;
my $actualsize = $polysize + 1;
my $txn;
open (TXNLIST, $txnlistfile) or die "can't open $txnlistfile!";
my @txnlist = <TXNLIST>;
print "\nMy polysize for this loop is $actualsize\n";

foreach my $line(@txnlist){
  if ($line =~ /^TRANS.*/){
    $txn = $line;
    }
  if ($line =~ />\d+,$actualsize/){
    my $polymerinfo = $line;
    print OUTFILE "$txn";
    print OUTFILE "$polymerinfo";
  }
}
return;
}
