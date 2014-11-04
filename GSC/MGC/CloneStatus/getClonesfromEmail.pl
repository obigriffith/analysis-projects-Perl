#!/usr/local/bin/perl -w

use strict;

my $email = "MGC_lagging_clone_list.txt";
my $outfile = "clonelist.txt";
open (INFILE, $email) or die "can't open $email";
open (OUTFILE, ">$outfile") or die "can't open $outfile";

my @list = <INFILE>;
foreach my $line(@list){
  if ($line =~ /^\s+(\d+)\s.+\s\d+\s\d+/){
    print OUTFILE $1,"\n";
  }
}
exit;

