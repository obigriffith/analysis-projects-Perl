#!/usr/bin/perl -w

use strict;

my $oreg_datafile = "/home/obig/Projects/oreganno/scripts/for_UCSC/oreganno_FULL_27Jul07.txt";
my $dup_seqs_file = "/home/obig/Projects/oreganno/scripts/for_UCSC/REST_dataset_duplicate_upload_seqs.txt";

my %oreg_data;

open (OREGDATA, $oreg_datafile) or die "can't open $oreg_datafile\n";
while (<OREGDATA>){
  my @data=split("\t", $_);
  if ($data[19] eq "NRSF/REST ChIPSeq sites"){
    my $stable_id=$data[9];
    my $seq_with_flank=$data[22];
    #print "$data[9]\t$data[19]\t$data[22]\n";
    $oreg_data{$seq_with_flank}{$stable_id}++;
  }
}
close(OREGDATA);

open (DUPSEQS, $dup_seqs_file) or die "can't open $dup_seqs_file\n";
while (<DUPSEQS>){
  my $seq = $_;
  chomp $seq;
  if ($oreg_data{$seq}){
    my $oreg_highest_id=0;
    my $oreg_highest_stable_id;
    #print "checking duplicate records for higher id ";
    foreach my $oregdup (keys %{$oreg_data{$seq}}){
      #print "$oregdup ";
      if ($oregdup=~/OREG(\d+)/){
	my $oreg_id=$1;
	if ($oreg_id>$oreg_highest_id){
	  $oreg_highest_id=$oreg_id;
	  $oreg_highest_stable_id=$oregdup;
	}
      }
      #print "$oregdup\t$seq\n";
    }
    print "$oreg_highest_stable_id\n";
  }
}
