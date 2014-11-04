#!/usr/bin/perl -w

use strict;
use Data::Dumper;
use Getopt::Std;

my (%PLATFORM1, %PLATFORM2, %PLATFORM1_BEST, %PLATFORM2_BEST, %summary, %results, %best_results);
my (@x, @y, @r);

my $platform1results = "sagetest2.txt";
my $platform2results = "microtest2.txt";
my $neighborhood = 10;

#load platform1 results
print "\nLoading platform1 results into hash\n";
open (PLATFORM1RESULTS, $platform1results) or die "can't open $platform1results\n";
my $platform1count = 0;
while(<PLATFORM1RESULTS>) {
  if ($_=~/^(\S+)\s+(\S+)\s+(\S+)/){
    push(@x,$1);
    push(@y,$2);
    push(@r,$3);
  }
}
# randomize @r only.  If we randomize either @x or @y we end up with weird gene pairs (2 vs 2, or multiple pairs that are the same)
@r = sort { rand() <=> rand() } @r;

for my $gene1 (@x) {
  # pick a random $y,$r
  my $gene2 = shift @y;
  my $r = shift @r;
  $PLATFORM1{$gene1}{$gene2} = $r;
  $PLATFORM1{$gene2}{$gene1} = $r;
  $platform1count++;
  print "Platform1 results loaded: $platform1count\r";
}

#Attempt to reinitialize these variables
@x = (); @y = (); @r = ();


#Find best n matches for each gene in platform1 and create a new smaller hash
print "\nSorting and transferring Platform1 top $neighborhood matches to smaller hash\n";
my $platform1_bestcount = 0;
foreach my $gene1 (sort {rand() <=> rand()} keys %PLATFORM1){
  my $i = 1;
  foreach my $gene2 (sort {$PLATFORM1{$gene1}{$a} <=> $PLATFORM1{$gene1}{$b}} (keys(%{$PLATFORM1{$gene1}}))){
    if ($i <= $neighborhood){
      $PLATFORM1_BEST{$gene1}{$gene2}=$PLATFORM1{$gene1}{$gene2};
      $platform1_bestcount++;
      print "Platform1 best results loaded: $platform1_bestcount\r";
      $i++;
    }else{
      last;
    }
  }
}

#load platform2 results
print "\n\nLoading platform2 results into hash\n";
open (PLATFORM2RESULTS, $platform2results) or die "can't open $platform2results\n";
my $platform2count = 0;

while(<PLATFORM2RESULTS>) {
  if ($_=~/^(\S+)\s+(\S+)\s+(\S+)/){
    push(@x,$1);
    push(@y,$2);
    push(@r,$3);
  }
}
# randomize @r only.  If we randomize either @x or @y we end up with weird gene pairs (2 vs 2, or multiple pairs that are the same)
@r = sort { rand() <=> rand() } @r;

for my $gene1 (@x) {
  # pick a random $y,$r
  my $gene2 = shift @y;
  my $r = shift @r;
  $PLATFORM2{$gene1}{$gene2} = $r;
  $PLATFORM2{$gene2}{$gene1} = $r;
  $platform2count++;
  print "Platform2 results loaded: $platform2count\r";
}

#Attempt to reinitialize these variables
@x = (); @y = (); @r = ();

#Find best n matches for each gene in platform1 and create a new smaller hash
print "\nSorting and transferring Platform2 top $neighborhood matches to smaller hash\n";
my $platform2_bestcount = 0;
foreach my $gene1 (sort {$a <=> $b} keys %PLATFORM2){
  my $i = 1;
  foreach my $gene2 (sort {$PLATFORM2{$gene1}{$b} <=> $PLATFORM2{$gene1}{$a}} (keys(%{$PLATFORM2{$gene1}}))){
    if ($i <= $neighborhood){
      $PLATFORM2_BEST{$gene1}{$gene2}=$PLATFORM2{$gene1}{$gene2};
      $platform2_bestcount++;
      print "Platform2 best results loaded: $platform2_bestcount\r";
      $i++;
    }else{
      last;
    }
  }
}

print "\n\n-----------Platform1-------------------\n";
#print Dumper (%PLATFORM1_BEST);
foreach my $gene1 (sort keys %PLATFORM1_BEST){
  foreach my $gene2 (sort keys %{$PLATFORM1_BEST{$gene1}}){
    print "$gene1\t$gene2\t$PLATFORM1_BEST{$gene1}{$gene2}\n";
  }
}

print "\n\n-----------Platform2-------------------\n";
#print Dumper (%PLATFORM2_BEST);
foreach my $gene1 (sort keys %PLATFORM2_BEST){
  foreach my $gene2 (sort keys %{$PLATFORM2_BEST{$gene1}}){
    print "$gene1\t$gene2\t$PLATFORM2_BEST{$gene1}{$gene2}\n";
  }
}
