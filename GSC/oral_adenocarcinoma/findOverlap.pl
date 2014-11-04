#!/usr/bin/perl -w

use strict;
use Data::Dumper;

my $exp_file="tumor_merged_vs_others_up_down.txt";
my $copy_file="oct20.amps_dels_72vs4_v1_regions_only.clean";

my %copy;
my $copy_count=0;

open (COPY, $copy_file) or die "can't open $copy_file\n";
my $copy_header=<COPY>;
chomp $copy_header;
while (<COPY>){
  $copy_count++;
  chomp;
  my @data=split("\t",$_);
  $copy{$copy_count}{'chr'}=$data[0];
  $copy{$copy_count}{'start'}=$data[1];
  $copy{$copy_count}{'end'}=$data[2];
  $copy{$copy_count}{'copy_num'}=$data[3];
}
close COPY;

#print Dumper(%copy);

open (EXP, $exp_file) or die "can't open $exp_file\n";
my $exp_header=<EXP>;
print "$copy_header\t$exp_header";
while (<EXP>){
  my $line = $_;
  my @data=split("\t",$line);
  my $chr=$data[1];
  $chr=~s/chr//g;
  my $start=$data[2];
  my $end=$data[3];

  #Check for amp/dels in copy data
  foreach my $copy_count (sort keys %copy){
    if ($chr eq $copy{$copy_count}{'chr'}){
      if (($start>$copy{$copy_count}{'start'} && $start<$copy{$copy_count}{'end'}) || ($end>$copy{$copy_count}{'start'} && $end<$copy{$copy_count}{'end'})){
	print "$copy{$copy_count}{'chr'}\t$copy{$copy_count}{'start'}\t$copy{$copy_count}{'end'}\t$copy{$copy_count}{'copy_num'}\t$line";
      }
    }
  }
}
close EXP;
