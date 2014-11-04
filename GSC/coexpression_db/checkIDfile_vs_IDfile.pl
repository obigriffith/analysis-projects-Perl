#!/usr/local/bin/perl -w

use strict;

my $ref_file = "/home/obig/clustering/coexpression_db/ensembl_mapping/LL_list_all";
my $query_file = "/home/sage/clustering/matrix/affy_micro_sage_comp/040407/results/for_coexpression_db/sage_genes_uniq";
my %ref_IDs;

open (REFFILE, $ref_file) or die "can't open $ref_file\n";

my $ref_count = 0;
while (<REFFILE>){
  if ($_=~/(\S+)/){
    $ref_IDs{$1}=$1;
    $ref_count++;
  }
}
close REFFILE;
print "$ref_count reference IDs found\n";

open (QUERYFILE, $query_file) or die "can't open $query_file\n";
my $query_count=0;
my $common_count=0;
while (<QUERYFILE>){
  if ($_=~/(\S+)/){
    $query_count++;
    if ($ref_IDs{$1}){
      $common_count++;
    }
  }
}
print "$query_count query IDs found\n";
print "$common_count IDs common to reference file\n";

exit;
