#!/usr/bin/perl -w

use strict;

$/="^"; #seperate each record on "^";
my $empty_record=<>;

print "sample\tsource\tprimary_site\thistology\tgender\tethnicity\ttobacco_use\talcohol_use\n";
while (<>){
  my $record=$_;
  my $sample="NA";
  my $primary_site="NA";
  my $histology="NA";
  my $gender="NA";
  my $source="NA";
  my $ethnicity="NA";
  my $tobacco_use="NA";
  my $alcohol_use="NA";

  if ($record=~/SAMPLE\s*\=\s*(GSM\d+)/){
    $sample=$1;
  }
  if ($record=~/Sample_source_name_ch1\s*\=\s*(\w+.*)/){
    $source=$1;
  }
  if ($record=~/Primary Site\:\s*(\w+.*)/){
    $primary_site=$1;
  }
  if ($record=~/Histology\:\s*(\w+.*)/){
    $histology=$1;
  }
  if ($record=~/Gender\:\s*(\w+)/){
    $gender=$1;
  }
  if ($record=~/Ethnic Background\:\s*(\w+.*)/){
    $ethnicity=$1;
  }
  if ($record=~/Tobacco Use\s*\:\s*(\w+.*)/){
    $tobacco_use=$1;
  }
    if ($record=~/Alcohol Consumption.*\:\s*(\w+.*)/){
    $alcohol_use=$1;
  }
  print "$sample\t$source\t$primary_site\t$histology\t$gender\t$ethnicity\t$tobacco_use\t$alcohol_use\n";
}
