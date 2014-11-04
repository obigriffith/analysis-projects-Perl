#!/usr/bin/perl -w

use strict;
use Data::Dumper;
my $datafolder = "/home/obig/Projects/oral_adenocarcinoma/solexa_data/maq_analysis/gene_level/v3/";
opendir(DIR, $datafolder) || die "can't opendir $datafolder: $!";
my @datafiles = readdir(DIR);
#print Dumper (@datafiles);
closedir DIR;

my %Data;
my %Files;

foreach my $file (@datafiles){
  if ($file=~/HS.+\.gene/){
    $Files{$file}++;
    my $filepath="$datafolder"."$file";
    print STDERR "processing $filepath\n";
    open (DATAFILE, $filepath) or die "can't open $filepath\n";
    while (<DATAFILE>){
      chomp;
      my @data=split ("\t", $_);
      $Data{$data[0]}{'chr'}=$data[1];
      $Data{$data[0]}{'start'}=$data[2];
      $Data{$data[0]}{'end'}=$data[3];
      $Data{$data[0]}{'length'}=$data[4];
      $Data{$data[0]}{'seq_bases'}{$file}=$data[5];
    }
    close DATAFILE;
  }
}

my @files=sort keys %Files;
print "gene\tchr\tstart\tend\tlength\t",join("\t", @files),"\n";

foreach my $gene (sort keys %Data){
  my $chr = $Data{$gene}{'chr'};
  my $start = $Data{$gene}{'start'};
  my $end = $Data{$gene}{'end'};
  my $length = $Data{$gene}{'length'};
  my @seq_bases;
  foreach my $file (sort keys %{$Data{$gene}{'seq_bases'}}){
    push (@seq_bases, $Data{$gene}{'seq_bases'}{$file});
  }
  print "$gene\t$chr\t$start\t$end\t$length\t",join("\t",@seq_bases),"\n";
}


