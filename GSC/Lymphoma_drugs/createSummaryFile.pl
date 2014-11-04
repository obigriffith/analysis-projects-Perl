#!/usr/bin/perl -w

use strict;
use Data::Dumper;

my $drug_mapping="drugcard_drugtarget_swissprot_ids.txt";

#FL analysis
#my $gcrma_data="FL/FL_vs_normGCBcell_gcrma.txt";
#my $sigprobesfile="FL/up_regulated/FL_vs_normGCBcell.sigprobes.adjpvalues.txt";
#my $uniprot_mapping="FL/up_regulated/FL_vs_normGCBcell.sigprobes_2_Biomart_uniprot_swissprot_unambig_mappings.txt";
#my $sigprobesfile="FL/down_regulated/FL_vs_normGCBcell.sigprobes.adjpvalues.txt";
#my $uniprot_mapping="FL/down_regulated/FL_vs_normGCBcell.sigprobes_2_Biomart_uniprot_swissprot_unambig_mappings.txt";
#my $sigprobesfile="FL/diff_regulated/FL_vs_normGCBcell.sigprobes.adjpvalues.txt";
#my $uniprot_mapping="FL/diff_regulated/FL_vs_normGCBcell.sigprobes_2_Biomart_uniprot_swissprot_unambig_mappings.txt";

#DLBCL analysis
my $gcrma_data="DLBCL/DLBCL_vs_normGCBcell_gcrma.txt";
#my $sigprobesfile="DLBCL/up_regulated/DLBCL_vs_normGCBcell.sigprobes.adjpvalues.txt";
#my $uniprot_mapping="DLBCL/up_regulated/DLBCL_vs_normGCBcell.sigprobes_2_Biomart_uniprot_swissprot_unambig_mappings.txt";
#my $sigprobesfile="DLBCL/down_regulated/DLBCL_vs_normGCBcell.sigprobes.adjpvalues.txt";
#my $uniprot_mapping="DLBCL/down_regulated/DLBCL_vs_normGCBcell.sigprobes_2_Biomart_uniprot_swissprot_unambig_mappings.txt";
my $sigprobesfile="DLBCL/diff_regulated/DLBCL_vs_normGCBcell.sigprobes.adjpvalues.txt";
my $uniprot_mapping="DLBCL/diff_regulated/DLBCL_vs_normGCBcell.sigprobes_2_Biomart_uniprot_swissprot_unambig_mappings.txt";

#Read in gcrma expression data
my %gcrma;
open (GCRMA, $gcrma_data) or die "can't open $gcrma_data\n";
my $gcrma_header=<GCRMA>;
chomp $gcrma_header;
while(<GCRMA>){
  my $data=$_;
  chomp $data;
  if ($data=~/^(\S+)\t(.+)/){
    $gcrma{$1}=$2;
  }
}
close GCRMA;

#Read in uniprot mappings
my %probe2uni;
open (UNIPROT, $uniprot_mapping) or die "can't open $uniprot_mapping\n";
my $uniprot_header=<UNIPROT>;
chomp $uniprot_header;
while(<UNIPROT>){
  my $data=$_;
  chomp $data;
  if ($data=~/^(\S+)\t(\w+)/){
    $probe2uni{$1}=$2;
  }
}
close UNIPROT;

#Read in uniprot to drug mappings
my %drugs;
open (DRUGS, $drug_mapping) or die "can't open $drug_mapping\n";
while(<DRUGS>){
  my $data=$_;
  chomp $data;
  if ($data=~/^(\w+)\t(\w+)/){
    $drugs{$2}{$1}++;
  }
}
close DRUGS;


#Now, go through all significant probes and combine with other data
open (SIGPROBES, $sigprobesfile) or die "can't open $sigprobesfile\n";
my $sigprobeheader=<SIGPROBES>;
chomp $sigprobeheader;

#Print all column headers
print "$sigprobeheader\tuniprot_id\tdrugs\t$gcrma_header\n";

while (<SIGPROBES>){
  my $sigprobe = $_;
  chomp $sigprobe;
  my @sigprobedata=split("\t", $sigprobe);
  my $probe_id=$sigprobedata[0];

  #Retrieve uniprot id (if available)
  my $uniprot_id;
  if ($probe2uni{$probe_id}){
    $uniprot_id=$probe2uni{$probe_id};
  }else{
    $uniprot_id="NA";
  }

  #Retrieve drug(s) for uniprots (if available)
  my $drugs;
  if ($uniprot_id eq "NA"){
    $drugs="NA";
  }else{
    if ($drugs{$uniprot_id}){
      my @drugs;
      foreach my $drug (sort keys %{$drugs{$uniprot_id}}){
	push (@drugs, $drug);
      }
      $drugs=join(";",@drugs);
    }else{
      $drugs="NA";
    }
  }

  print "$sigprobe\t$uniprot_id\t$drugs\t$gcrma{$probe_id}\n";

#  print "$probe_id\n";
#  print "$gcrma{$probe_id}\n\n";
}
close SIGPROBES;
