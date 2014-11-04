#!/usr/bin/perl -w

use strict;
use Getopt::Std;

#This scipts parses the output of findCoOccMotifs2.pl to get the genes in each cluster defined by coocurrence


getopts("f:");
use vars qw($opt_f);
unless ($opt_f){print "usage: getModuleClusters.pl -f modulefile";exit;}
#my $ModuleFile = "/home/obig/Projects/cisRED_coexpression/commonModuleAnalysis/cisred_1_2a.6.coocc";
my $ModuleFile = $opt_f;
my %module_gene_cluster;

open (MODULEFILE, $ModuleFile) or die "can't open $ModuleFile\n";
while(<MODULEFILE>){
  my @entry = split("\t",$_);

  my $module="$entry[0]"."_"."$entry[1]";
  my $rev_module="$entry[1]"."_"."$entry[0]";
  my $geneA = $entry[4];
  my $geneB = $entry[5];
  unless ($module eq $rev_module){
    if($module_gene_cluster{$rev_module}){
      print "\n\nwarning reverse modules present\n\n";
      exit;
    }
  }#each motif cooccurence should only appear in one form (accA_accB or accB_accA, but watch for accA_accA)
  $module_gene_cluster{$module}{$geneA}++;
  $module_gene_cluster{$module}{$geneB}++;
}
close MODULEFILE;

foreach my $module (sort keys %module_gene_cluster){
  my @genes;
  foreach my $gene (sort keys %{$module_gene_cluster{$module}}){
    push (@genes, $gene);
  }
  my $genecount=@genes;
  if ($genecount>1){
    print "$module\t",join(" ",@genes),"\n";
  }
}
