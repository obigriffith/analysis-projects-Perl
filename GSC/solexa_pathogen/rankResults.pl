#!/usr/bin/perl -w

use strict;
use Data::Dumper;
use Getopt::Std;

getopts("f:");
use vars qw($opt_f);

my ($infile);
my %target;
my %query;
my %query_target;
my %target_totals;

if ($opt_f){
  $infile=$opt_f;
  open (INFILE, $infile) or die "can't open $infile\n";
}else{
  print "missing options
usage: rankResults.pl -f interest.out\n";
  exit;
}

$/="------------";
while (<INFILE>){
  my ($query, $count, $target);
  if ($_=~/Query\:\s\w+\:\w+\:(\w+)\:(\d+)/){
    $query=$1;
    $count=$2;
    #print "$query\t$count\n";
  }
  if ($_=~/Target\:\s(.+)/){
    $target=$1;
    chomp $target;
    $target=~s/\:\[revcomp\]//g; #Get rid of revcomp hits for summarization purposes
    #print "$target\n\n";
  }

  #Check to see if query/target combo already exists and skip (e.g., revcomp and non-revcomp versions)
  if ($query_target{$query}{$target}){
    next;
  }

  if ($query && $count && $target){
    $target{$target}++;
    $query{$query}{'target'}=$target;
    $query{$query}{'count'}=$count;
    $query_target{$query}{$target}++;
    $target_totals{$target}{'tagtotal'}+=$count;
    $target_totals{$target}{'hitcount'}++;
  }
}

#print Dumper (%target);
#print Dumper (%query);
#print Dumper (%target_totals);

foreach my $target (sort keys %target_totals){
  my $tagtotal=$target_totals{$target}{'tagtotal'};
  my $hitcount=$target_totals{$target}{'hitcount'};
  print "$tagtotal\t$hitcount\t$target\n";
}
