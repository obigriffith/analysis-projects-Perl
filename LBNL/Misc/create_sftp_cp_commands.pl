#!/usr/bin/perl -w

use strict;

my $config_file="/csb/home/obig/ALEXA/config_files/ALEXA_Seq_BCCL.conf";
my $outfile="/csb/home/obig/Projects/RNAseq/sftp_cp_commands.txt";

open (CONFIG, $config_file) or die "can't open $config_file\n";
open (OUTFILE, ">$outfile") or die "can't open $outfile for write\n";

my %lanes;
my %libs;

while (<CONFIG>){
  #Get each lane data path and library name
  if ($_=~/LANE\s+(\S+)\s+(\S+)\s+(\d+)\s+(\S+)/){
    my $lib_id=$1;
    my $flowcell=$2;
    my $lane=$3;
    my $path=$4;
    $lanes{$flowcell}{$lane}{'lib_id'}=$lib_id;
    $lanes{$flowcell}{$lane}{'path'}=$path;
  }
  #Get library names
  if ($_=~/LIBRARY\s+(\S+)\s+(\S+)/){
    $libs{$1}=$2;
  }
}

#Find fastq files
foreach my $flowcell (sort keys %lanes){
  foreach my $lane (sort keys %{$lanes{$flowcell}}){
    my $lib_name=$libs{$lanes{$flowcell}{$lane}{'lib_id'}};
    my $path=$lanes{$flowcell}{$lane}{'path'};
    my $target_name_R1="$lib_name"."_"."$flowcell"."_"."$lane"."_"."1"."_sequence.txt.gz";
    my $target_name_R2="$lib_name"."_"."$flowcell"."_"."$lane"."_"."2"."_sequence.txt.gz";

    #print "$flowcell  $lane  $lib_name  $path\n";
    my $ls_cmd1="ls "."$path"."GERALD*/s_"."$lane"."_1_sequence.txt.gz";
    my $ls_cmd2="ls "."$path"."GERALD*/s_"."$lane"."_2_sequence.txt.gz";

    my $read1_path=`$ls_cmd1`;
    my $read2_path=`$ls_cmd2`;

    if ($read1_path=~/(\/\S+GERALD_\d+\S+\.txt\.gz)/){
      $read1_path=$1;
      print OUTFILE "put $read1_path $target_name_R1\n";
    }
    if ($read2_path=~/(\/\S+GERALD_\d+\S+\.txt\.gz)/){
      $read2_path=$1;
      print OUTFILE "put $read2_path $target_name_R2\n";
    }


  }
}
close CONFIG;
close OUTFILE;


