#!/usr/local/bin/perl -w

#############################################
#Creates a single file containg all the vector and library names for each clone
#for each plate in the "/home/sequence/Projects/Human_cDNA/ESTs/RearrayedPlates"
#Make sure these files are up to date by running getplates.pl
##############################################

use strict;

my $outfile = "/mnt/disk1/home/obig/perl/MGC_PolyA_Analysis/VectorLibraryList.txt";
open(OUTFILE,">$outfile") or die "can not open $outfile for output";

my $dir = "/home/sequence/Projects/Human_cDNA/ESTs/RearrayedPlates";
chdir "$dir" or die "can not cd to $dir:\n";

opendir FILELIST, "$dir";
my @filelist = readdir FILELIST;
closedir FILELIST;

#print "@filelist\n";

foreach my $file(@filelist){

  my @temp = ();
  if ($file =~ /^IRA[K,L]\d+$/){
    open(TEMPFILE, $file);
    @temp = <TEMPFILE>;
    close TEMPFILE;
    print OUTFILE @temp,"\n";
  }
}
close OUTFILE;
exit;
