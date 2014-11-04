#!/usr/bin/perl -w

use strict;

my $queue_pmids_file="All_PMIDs_in_queue_uniq.txt";
my $record_pmids_file="All_PMIDs_in_records_uniq.txt";

my %queue_pmids;
my %record_pmids;

#Load pmids from queue list
open (QUEUE, $queue_pmids_file);
while (<QUEUE>){
  if ($_=~/\d+/){
    my $queue_pmid=$_;
    chomp $queue_pmid;
    $queue_pmids{$queue_pmid}++;
  }
}
close QUEUE;

#Load pmids from records list
open (RECORDS, $record_pmids_file);
while (<RECORDS>){
  if ($_=~/\d+/){
    my $record_pmid=$_;
    chomp $record_pmid;
    $record_pmids{$record_pmid}++;
  }
}
close RECORDS;

#Check each pmid in the records list. If it is not in the queue list, print it out
foreach my $pmid(keys %record_pmids){
  unless ($queue_pmids{$pmid}){
    print "$pmid\n";
  }
}
