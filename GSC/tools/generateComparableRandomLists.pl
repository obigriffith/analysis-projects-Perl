#!/usr/bin/perl -w

use strict;
use Data::Dumper;
use Getopt::Std;

###This script generates gene clusters such that the cluster sizes and numbers are the same as a reference file
getopts("r:t:o:i:nd");
use vars qw($opt_t $opt_r $opt_o $opt_n $opt_d $opt_i);

srand(time() ^($$ + ($$ <<15))) ;

my $totalset = $opt_t; #list of entities from which to choose (eg. unique gene list)
my $reflistfile = $opt_r; #File containing reference list of groups - an output file will be created with the same numbers and sizes of groups but created randomly from using the total list

unless ($opt_r && $opt_t){
  print "usage: generateComparableRandomLists.pl -n -d -t uniqgenelistfile -r refclusterfile -o outfile -i 100
required:
-t file with uniq list of genes
-r reference cluster/grouping file (tells script how many groups and of what sizes to create)

options:
-o output file (If not using -i option this is not required.  A single random result will be printed to stdout)
-n if each row/cluster starts with a name
-d if duplicate entries in a group should be allowed
-i Number of random datasets to create (must be used in combination with -o option as basename for multiple output files
";
exit;}

my $num_rand_files=1;#Assume only one random result is desired unless specified otherwise with opt_i
if ($opt_i){
  $num_rand_files=$opt_i;
}

#First load total entity list into an array
my @total_entities;
open (TOTALSET, $totalset) or die "can't open $totalset\n";
while (<TOTALSET>){
chomp $_;
push (@total_entities, $_);
}
close TOTALSET;
my $num_total_entities = @total_entities;

#Now determine number and sizes of random groups that need to be chosen based on the reference file
#expecting a tab-delimited group per line)
my %groupsizes;
my @groupsizes;
open (REFFILE, $reflistfile) or die "can't open $reflistfile\n";
while (<REFFILE>){
  chomp $_;
  my @group = split("\t", $_);
  if ($opt_n){shift @group;}#If there are row names, remove them
  my $groupsize = @group;
  push (@groupsizes, $groupsize);
}
close REFFILE;

my $i;
for ($i=1; $i<=$num_rand_files; $i++){
  #Create an outputfile handle if requested
  my $outfile;
  if ($opt_o){
    $outfile=$opt_o;
    #If multiple random files requested, create numbered outputfile handle based on iteration count
    if ($opt_i){
      $outfile="$outfile"."."."$i";
    }
    open (OUTFILE, ">$outfile") or die "can't open $outfile for output\n";
  }
  my $j=0;
  foreach my $groupsize (@groupsizes){
    my @randgroup=();
    my %randgroup_entities=();
    my $m;
    for ($m=1; $m<=$groupsize; $m++){#For m entities
      my $rand_number = int(rand($num_total_entities));
      my $rand_entity = $total_entities[$rand_number];
      if ($opt_d){ #If duplicates are acceptable, add entry to array and continue to the next random selection
	push (@randgroup, $rand_entity);
	next;
      }else{ #If duplicates are not desired
	#if entity has already been picked for this cluster pick another one
	if ($randgroup_entities{$rand_entity}){
	  $m=$m-1;
	}else{
	  $randgroup_entities{$rand_entity}++;
	  push (@randgroup, $rand_entity);
	}
      }
    }
    if ($opt_n){my $randlistid="rand"."$j"; unshift(@randgroup,$randlistid);} #If row names were specified create a simple rowname for each list so that the file is of the same format
    if ($opt_o){
      print OUTFILE join("\t", @randgroup),"\n";
    }
    unless ($opt_i){print join("\t", @randgroup),"\n";} #only print output to screen when doing one file
    $j++;
  }
  if ($opt_o){close OUTFILE;}
  if ($opt_i){print "Random file created: $outfile\n";}
}
