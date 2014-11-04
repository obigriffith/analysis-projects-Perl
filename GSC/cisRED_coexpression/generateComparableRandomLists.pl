#!/usr/bin/perl -w

use strict;
use Data::Dumper;
use Getopt::Std;

###This script generates gene clusters such that the cluster sizes and numbers are the same as a reference file
getopts("r:t:o:");
use vars qw($opt_t $opt_r);

srand(time() ^($$ + ($$ <<15))) ;

my $totalset = $opt_t; #list of entities from which to choose (eg. unique gene list)
my $reflistfile = $opt_r; #File containing reference list of groups - an output file will be created with the same numbers and sizes of groups but created randomly from using the total list

unless ($opt_r && $opt_t){print "usage: generateComparableRandomLists.pl -t uniqgenelistfile -r refclusterfile\n";exit;}

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
#expecting clustername   gene1 gene2 gene3)
my %groupsizes;
open (REFFILE, $reflistfile) or die "can't open $reflistfile\n";
while (<REFFILE>){
  chomp $_;
  my @line = split("\t", $_);
  my @group = split(" ", $line[1]);
  my $groupsize = @group;
  $groupsizes{$groupsize}++;
}
close REFFILE;

foreach my $groupsize (sort{$a<=>$b} keys %groupsizes){
  my $num_groups = $groupsizes{$groupsize};
  my $n;
  for ($n=1; $n<=$num_groups; $n++){ #For n groups
    my @randgroup=();
    my %randgroup_entities=();
    my $m;
    for ($m=1; $m<=$groupsize; $m++){#For m entities
      my $rand_number = int(rand($num_total_entities));
      my $rand_entity = $total_entities[$rand_number];
      if ($randgroup_entities{$rand_entity}){#if entity has already been picked for this cluster, pick another one
	$m=$m-1;
      }else{
	$randgroup_entities{$rand_entity}++;
	push (@randgroup, $rand_entity);
      }
    }
    print "randclust","$groupsize"."_"."$n\t",join(" ", @randgroup),"\n";
  }
}
