#!/usr/local/bin/perl -w

use strict;
use Data::Dumper;

my $mgc_map_file = "/home/obig/Projects/thyroid/mapping_files/SAGE/Thyroid_literature_data_summary2_Tag_uniqlist_mapped_MGC_SensePos1_to_Entrez.tsv";
my $refseq_map_file = "/home/obig/Projects/thyroid/mapping_files/SAGE/Thyroid_literature_data_summary2_Tag_uniqlist_mapped_REFSEQ_SensePos1_to_Entrez.tsv";

my %TagMap;

#Get mapping data for MGC
open (MGCMAP, $mgc_map_file) or die "can't open $mgc_map_file\n";
my $mgcfirstline=<MGCMAP>;
chomp $mgcfirstline;
my @mgc_headers = split ("\t",$mgcfirstline);
#print Dumper (@mgc_headers);

while (<MGCMAP>){
  chomp $_;
  my @mapdata = split("\t", $_);
  my $tag = $mapdata[1];
  my $gene = $mapdata[6];
  if ($tag && $gene){
    $TagMap{$tag}{$gene}++;
    #print "$tag\t$gene\n";
  }
}
close MGCMAP;

#Get mapping data for refseq
open (REFSEQMAP, $refseq_map_file) or die "can't open $refseq_map_file\n";
my $refseqfirstline=<REFSEQMAP>;
chomp $refseqfirstline;
my @refseq_headers = split ("\t",$refseqfirstline);
#print Dumper (@refseq_headers);
while (<REFSEQMAP>){
  chomp $_;
  my @mapdata = split("\t", $_);
  my $tag = $mapdata[1];
  my $gene = $mapdata[6];
  if ($tag && $gene){
    $TagMap{$tag}{$gene}++;
    #print "$tag\t$gene\n";
  }
}
close REFSEQMAP;

#print Dumper(%TagMap);
foreach my $tag (sort keys %TagMap){
  foreach my $gene (sort keys %{$TagMap{$tag}}){
    my $gene_count = keys %{$TagMap{$tag}};
    if ($gene_count == 1){
      print "$tag\t$gene\n";
    }
  }
}
