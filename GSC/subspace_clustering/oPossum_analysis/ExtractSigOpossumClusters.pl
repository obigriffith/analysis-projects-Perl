#!/usr/bin/perl -w

use strict;
use Data::Dumper;
use Getopt::Std;

getopts("d:t:");
use vars qw($opt_d $opt_t);

my $result_dir = $opt_d;
my $threshold=$opt_t;

my @result_files = `ls $result_dir`;
my %summary_stats;

foreach my $result_file (@result_files){
  chomp $result_file;
  my $clustername;
  if ($result_file=~/(cluster\d+)\.ztest/){
    $clustername=$1;
    my $result_path="$result_dir/$result_file";
    open (RESULT, $result_path) or die "can't open $result_file\n";
    my $firstline=<RESULT>;
    my $max_score=0;
    my $max_score_TF;
    while (<RESULT>){
      if ($_=~/(\S+)\s+\S+\t+\S+\t+\S+\t+\S+\t+(\S+)/){}
      my $score=$2;
      my $TF=$1;
      if ($score>=$max_score){
	$max_score=$score;
	$max_score_TF=$TF;
      }
    }
    close RESULT;
    if ($max_score>=$threshold){
      print "$clustername\t$max_score_TF\t$max_score\n";
    }
  }
}
