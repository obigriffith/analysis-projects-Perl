#!/usr/bin/perl -w

use strict;

$/="BEGIN_DRUGCARD";

while(<>){
  my $record=$_;
  my $record_id;
  if ($record=~/Primary_Accession_No\:\n(\w+\d+)/g){
    $record_id=$1;
  }

  while ($record=~/Drug_Target.*SwissProt_ID\:\n(\w+\d+)/g){
    print "$record_id\t$1\n";
  }
}
