#!/usr/bin/perl -w

use strict;

my $sequences_file="FoxA2nodups.clean.sequence";

#First, load in all sequences obtained from UCSC
my %sequences;
open (SEQUENCES, $sequences_file) or die "can't open $sequences_file\n";
$/=">";
while (<SEQUENCES>){
  if ($_=~/mm8_ct_FoxA2nodups_.+\srange\=(\w+)\:(\d+)\-(\d+).+strand\=(\S+)\srepeatMasking\=none\n(.+)\n\>/s){
    my $chr=$1;
    my $start=$2;
    my $end=$3;
    my $strand=$4;
    my $sequence=$5;
    $sequence=~s/\n//g;
    $chr=~s/chr//g;
    #print "$chr\t$start\t$end\t$strand\t$sequence\n";
    my $coord_length=($end-$start)+1;
    my $string_length=length($sequence);
    unless ($coord_length==$string_length){print "$coord_length doesn't match $string_length\n";exit;}
    $sequences{$chr}{$start}{$end}=$sequence;
  }
}
close SEQUENCES;
$/="\n";

#Create XML file
my $date = "12-Sep-2008";

#First, start with header details
print "<?xml version=\"1.0\" encoding=\"ISO-8859-1\"?>\n<oreganno>\n <recordSet>\n";

#Then, for each site/sequence create the necessary update statements
foreach my $chr (sort keys %sequences){
  foreach my $start (sort keys %{$sequences{$chr}}){
    foreach my $end (sort keys %{$sequences{$chr}{$start}}){
      my $sequence=$sequences{$chr}{$start}{$end};
      print "  <record>\n";
      print "   <commentSet>\n";
      print "    <comment>\n";
      print "     <comment></comment>\n";
      print "     <date></date>\n";
      print "     <userName></userName>\n";
      print "    </comment>\n";
      print "   </commentSet>\n";
      print "	<dataset>OREGDS00014</dataset>\n";
      print "	<date>$date</date>\n";
      print "   <deprecatedByDate></deprecatedByDate>\n";
      print "   <deprecatedByStableId></deprecatedByStableId>\n";
      print "   <deprecatedByUser></deprecatedByUser>\n";

      print "   <evidenceSet>\n";
      print "    <evidence>\n";
      print "     <cellType>EV:0200061</cellType>\n";
      print "     <comment>Chromatin immunoprecipitation (ChIP) was performed on Adult female C57Bl/6J mouse liver tissue using Foxa2 [HNF-3-beta (M-20): sc-6554, Santa Cruz] antibody. Foxa2-bound DNA (4.7 ng) was  purified by SDS-PAGE to obtain 100-300 bp fragments and sequenced on an Illumina 1G sequencer. Resulting sequences were mapped to the NCBI Build 36 (mm8) reference mouse genome to produce 13 984 706 mapped reads that were extended to 200 bp length XSETs and overlapped to create peaks. To further define the peak dataset, each group of XSETs that represented DNA fragments with identical fragment start coordinates was collapsed to a single XSET. Peaks generated from the resulting filtered reads were thresholded at a peak height of 10, creating a high confidence set of 11475 Foxa2-binding sites with an estimated false discovery rate of 0.05.</comment>\n";
      print "     <date>$date</date>\n";
      print "     <evidenceClassStableId>OREGEC00001</evidenceClassStableId>\n";
      print "     <evidenceSubtypeStableId>OREGES00059</evidenceSubtypeStableId>\n";
      print "     <evidenceTypeStableId>OREGET00003</evidenceTypeStableId>\n";
      print "     <userName>obig</userName>\n";
      print "    </evidence>\n";
      print "   </evidenceSet>\n";

      print "   <geneId>UNKNOWN</geneId>\n";
      print "   <geneName>UNKNOWN</geneName>\n";
      print "   <geneSource>USER DEFINED</geneSource>\n";
      print "   <geneVersion></geneVersion>\n";
      print "   <id></id>\n";
      print "   <lociName></lociName>\n";
      print "   <metaDataSet></metaDataSet>\n";
      print "   <outcome>POSITIVE OUTCOME</outcome>\n";
      print "   <reference>18611952</reference>\n";
      print "   <scoreSet></scoreSet>\n";
      print "   <searchSpace></searchSpace>\n";

      print "   <sequence>\n";
      print "    <end>$end</end>\n";
      print "    <internalSequenceType>sequence</internalSequenceType>\n";
      print "    <sequence>$sequence</sequence>\n";
      print "    <start>$start</start>\n";
      print "    <sequence_region_name>$chr</sequence_region_name>\n";
      print "    <strand>1</strand>\n";
      print "    <ensembl_database_name>mus_musculus_core_46_36g</ensembl_database_name>\n";
      print "    <verified>true</verified>\n";
      print "   </sequence>\n";

      print "   <sequenceWithFlank>\n";
      print "    <end>$end</end>\n";
      print "    <internalSequenceType>sequence_with_flank</internalSequenceType>\n";
      print "    <sequence>$sequence</sequence>\n";
      print "    <start>$start</start>\n";
      print "    <sequence_region_name>$chr</sequence_region_name>\n";
      print "    <strand>1</strand>\n";
      print "    <ensembl_database_name>mus_musculus_core_46_36g</ensembl_database_name>\n";
      print "    <verified>true</verified>\n";
      print "   </sequenceWithFlank>\n";

      print "   <speciesName>Mus musculus</speciesName>\n";
      print "   <stableId></stableId>\n";
      print "   <tfId>15376</tfId>\n";
      print "   <tfName>Foxa2</tfName>\n";
      print "   <tfSource>NCBI</tfSource>\n";
      print "   <tfVersion></tfVersion>\n";
      print "   <type>REGULATORY REGION</type>\n";
      print "   <variationSet></variationSet>\n";
      print "  </record>\n";
    }
  }
}

#Then print end of file details
print " </recordSet>\n";
print " <speciesSet>\n";
print "  <species>\n";
print "   <name>Mus musculus</name>\n";
print "   <taxonId>10090</taxonId>\n";
print "  </species>\n";
print " </speciesSet>\n";
print " <userName>obig</userName>\n";
print "</oreganno>\n";
