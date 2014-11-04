#!/usr/local/bin/perl -w
use strict;
use Data::Dumper;

my $infile = "test.txt";

open (INFILE, $infile);

while (<INFILE>){
  my $line = $_;
  #print "$line\n";
#  $line=~s/[\[\]]//g; #replace problematic characters like '[' which will confound substitutions later
#  $line=~s/[\(\)]//g;
#  $line=~s/\|/ /g;
#  $line=~s/\\/ /g;
  my $match = 0;
  while ($line =~ /(\".*?\")/g){ #find entries between ""
    my $entry = $1;
    if ($entry=~/\,/){ #If entry contains commas, remove them
      my $newentry=$entry;
      $newentry=~s/\,//g;
      $line=~s/\Q$entry\E/$newentry/; #replace original entry with new one that does not contain commas
    }
  }
  $line=~s/\s+\"/\"/g; #remove spaces in front of quotes
  $line=~s/\"\s+/\"/g; #remove spaces after quotes
  $line=~s/\"//g; #remove quotes
  chomp $line;
  my @entries = split (",", $line, -1);
  print Dumper (@entries);
  #print "$line\n";
  print "\n\n";
}
