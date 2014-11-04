#!/usr/bin/perl -w

use strict;
use Data::Dumper;


#FL analysis
#my $gcrma_data="FL/FL_vs_normGCBcell_gcrma.2.txt";
#my $gcrma_data="FL/FL_gcrma.txt";
my $gcrma_data="FL/FL_EZH2_status_gcrma.txt";
#my $sigprobesfile="FL/diff_regulated/FL_vs_normGCBcell.sigprobes.adjpvalues.2.txt";
#my $sigprobesfile="FL/diff_regulated/FL_vs_normGCBcell.allprobes.adjpvalues.2.txt";
#my $sigprobesfile="FL/EZH2_mt_vs_wt/diff_regulated/EZH2_mt_vs_wt.sigprobes.adjpvalues.txt";
#my $sigprobesfile="FL/EZH2_mt_vs_wt/diff_regulated/EZH2_mt_vs_wt.sigprobes.adjpvalues.2.txt";
#my $sigprobesfile="FL/EZH2_mt_vs_wt/diff_regulated/EZH2_mt_vs_wt.sigprobes.adjpvalues.3.txt";
my $sigprobesfile="FL/EZH2_mt_vs_wt/diff_regulated/EZH2_mt_vs_wt.sigprobes.rawpvalues.3.txt";
#my $gene_mapping="FL/diff_regulated/FL_vs_normGCBcell.sigprobes_2_Biomart_HGNC_unambig_mappings.txt";
#my $gene_mapping="FL/EZH2_mt_vs_wt/diff_regulated/EZH2_mt_vs_wt.sigprobes_2_Biomart_HGNC_unambig_mappings.txt";
#my $gene_mapping="FL/EZH2_mt_vs_wt/diff_regulated/EZH2_mt_vs_wt.sigprobes_2_Biomart_HGNC_unambig_mappings.2.txt";
#my $gene_mapping="FL/EZH2_mt_vs_wt/diff_regulated/EZH2_mt_vs_wt.sigprobes_2_Biomart_HGNC_unambig_mappings.3.txt";
my $gene_mapping="FL/EZH2_mt_vs_wt/diff_regulated/EZH2_mt_vs_wt.sigprobes_rawp_2_Biomart_HGNC_unambig_mappings.3.txt";

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

#Read in gene mappings
my %probe2gene;
open (GENE, $gene_mapping) or die "can't open $gene_mapping\n";
my $gene_header=<GENE>;
chomp $gene_header;
while(<GENE>){
  my $data=$_;
  chomp $data;
  if ($data=~/^(\S+)\t(\w+)/){
    $probe2gene{$1}=$2;
  }
}
close GENE;

#Now, go through all significant probes and combine with other data
open (SIGPROBES, $sigprobesfile) or die "can't open $sigprobesfile\n";
my $sigprobeheader=<SIGPROBES>;
chomp $sigprobeheader;

#Print all column headers
print "$sigprobeheader\thgnc_id\t$gcrma_header\n";

while (<SIGPROBES>){
  my $sigprobe = $_;
  chomp $sigprobe;
  my @sigprobedata=split("\t", $sigprobe);
  my $probe_id=$sigprobedata[0];

  #Retrieve gene id (if available)
  my $gene_id;
  if ($probe2gene{$probe_id}){
    $gene_id=$probe2gene{$probe_id};
  }else{
    $gene_id="NA";
  }

  print "$sigprobe\t$gene_id\t$gcrma{$probe_id}\n";

#  print "$probe_id\n";
#  print "$gcrma{$probe_id}\n\n";
}
close SIGPROBES;
