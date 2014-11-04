#!/usr/bin/perl -w

use strict;
use Getopt::Std;

getopts("f:o:m:c:hn");
use vars qw($opt_f $opt_o $opt_m $opt_h $opt_n $opt_c);

#Take a file with things that need to be mapped, a map file and produce a new file with the new identities (eg. tag -> locuslink)
#Assumes that file is tab-delimeted and first column contains Id to be replaced.  Will look in first column of mapfile for this ID

my %MAP;
my ($infile, $mapfile, $outfile);
unless($opt_f && $opt_m){&printDocs();}
if ($opt_f){
  $infile = $opt_f;
}if ($opt_m){
  $mapfile = $opt_m;
}if ($opt_o){
  $outfile = $opt_o;
  open (OUTFILE, ">$outfile") or die "can't open $outfile\n";
}
my $columns = $opt_c || 1;
if ($columns>2){print "script can only handle 1 or 2 columns of IDs\n";exit;}

#Create a hash of mappings
open (MAPFILE, $mapfile) or die "can't open $mapfile\n";
while (<MAPFILE>){
  if ($_=~/^(\S+)\t(\S+)/){
    $MAP{$1}=$2;
  }
}

open (INFILE, $infile) or die "can't open $infile\n";
if ($opt_h){my $firstline = <INFILE>; print OUTFILE "$firstline";} #print header

if ($columns==1){ #If file has single column of IDs to map
  while (<INFILE>){
    my $line = $_;
    if ($line=~/^(\S+)\t/){
      my $ID = $1;
      my $ID_original=$ID; #$ID may have to be altered to search for it in map file
      if ($ID=~m/^FBGN/i){$ID=~s/FBGN/FBgn/;} #for drosophila data, make flybase friendly
      if ($ID=~m/^AT\dG/i){$ID=~tr/aTG/Atg/;} #For TIGR/AGI Ids
      my $NewID;
      if ($MAP{$ID}){
	$NewID=$MAP{$ID};
      }else{
	$NewID = 'n/a';
	print "No ID found for $ID in $mapfile\n"; 
      }
      if ($opt_n){ #if n option specified, don't print 'n/a' mappings
	if ($NewID eq 'n/a'){
	  print "skipping $ID\n";
	  next;
	}
      }
      print "replacing $ID_original with $NewID\n";
      $line =~ s/$ID_original/$NewID/;
      if ($opt_o){
	print OUTFILE "$line";
      }
    }
  }
}

if ($columns==2){ #If file has two columns of IDs to map
  while (<INFILE>){
    my $line = $_;
    my $missing_check=0;
    if ($line=~/(\S+)\s+(\S+)\s+(\S+)/){
      my $line_end=$3;
      my (@IDs,@NewIDs);
      push (@IDs, $1); push (@IDs, $2);
      for (my $i=0; $i<=1; $i++){
	my $ID=$IDs[$i];
	my $ID_original=$ID; #$ID may have to be altered to search for it in map file
	if ($ID=~m/^FBGN/i){$ID=~s/FBGN/FBgn/;} #for drosophila data, make flybase friendly
	if ($ID=~m/^AT\dG/i){$ID=~tr/aTG/Atg/;} #For TIGR/AGI Ids
	my $NewID;
	if ($MAP{$ID}){
	  $NewID=$MAP{$ID};
	}else{
	  $NewID = 'n/a';
	  print "No ID found for $ID in $mapfile\n"; 
	}
	if ($NewID eq 'n/a'){
	  $missing_check=1;
	}
	$NewIDs[$i]=$NewID;
      }
      if ($opt_n){ #if n option specified, don't print 'n/a' mappings
	if ($missing_check==1){print "missing IDs skipping line\n";next;} #if any missing entries detected above, skip to next line
      }
      print "$NewIDs[0]\t$NewIDs[1]\t$line_end\n";
      if ($opt_o){
	print OUTFILE "$NewIDs[0]\t$NewIDs[1]\t$line_end\n";
      }
    }
  }
}

close INFILE;

if ($opt_o){
close OUTFILE;
}
exit;

sub printDocs{
print "Takea a file with things that need to be mapped, a map file and produces a new file with the new identities (eg. tag -> locuslink)\n";
print "Assumes that file is tab-delimeted and first column contains Id to be replaced.  Will look in first column of mapfile for this ID\n";
print "Must supply at least -f and -m options.\n";
print "Options:\n";
print "-f file.txt   File with IDs to mapped to new IDs\n";
print "-m mapfile.txt   File with mapping of old IDs to new IDs\n";
print "-o outfile.txt   Print results of mapping to new file\n";
print "-c column_number   Specify number of columns (1 or 2) with IDs to map\n";
print "-h   specify if you wish to print header in new file\n";
print "-n   specify if you wish to print 'n/a' mappings.  'n' flag removes these lines from new file\n";
exit;
}
