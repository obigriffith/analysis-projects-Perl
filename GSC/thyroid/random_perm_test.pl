#!/usr/bin/perl -w

use strict;
use Data::Dumper;
use Getopt::Std;

getopts("f:r:o:t:u");
use vars qw($opt_f $opt_r $opt_o $opt_u $opt_t);
#srand(time() ^($$ + ($$ <<15))); #seed for random function - no longer necessary with modern version of Perl

my $comp_lists_file=$opt_f;
my $permutations= $opt_r;
my $outfile = $opt_o;
my $test_value = $opt_t; #provide number of multi-study genes to test against

if ($opt_o){
open (OUTFILE, ">$outfile") or die "can't open $outfile\n";
}

###Load complete gene list files
my $HG_U95A_v2 = "Entrez_list/HG_U95Av2.txt";
my $HG_U133A = "Entrez_list/HG_U133A.txt";
my $custom1807 = "Entrez_list/customArray_1807.txt";
my $custom27648 = "Entrez_list/customArray_27648.txt";
my $custom3968 = "Entrez_list/customArray_3968.txt";
my $custom5760 = "Entrez_list/customArray_5760.txt";
my $HsUnigem2 = "Entrez_list/Hs_UniGem2_human_cDNA_array_GPL1262_annot.LocusLink.txt";
my $AtlasCancer = "Entrez_list/7851-1_HuCan12Atlas_Human_cancer_cDNA_array_1176.LocusLink.txt";
my $Atlas = "Entrez_list/7740-1_Hu_Atlas_Human_cDNA_array_588.LocusLink.txt";
my $SAGE = "Entrez_list/Sample_SAGE_genelist.2.Entrez.txt";

my $sig_result_count=0;

#Each gene list will be stored in an array
my @HG_U95A_v2_array;
my @HG_U133A_array;
my @custom1807_array;
my @custom27648_array;
my @custom3968_array;
my @custom5760_array;
my @HsUnigem2_array;
my @AtlasCancer_array;
my @Atlas_array;
my @SAGE_array;

#Populate arrays with genes from genelist files
&readGeneListFiles;

#Create a hash to associate each of these arrays with a platform name
my %platform_array;
$platform_array{'HGU95Av2'}=\@HG_U95A_v2_array;
$platform_array{'HGU133A'}=\@HG_U133A_array;
$platform_array{'custom1807'}=\@custom1807_array;
$platform_array{'custom27648'}=\@custom27648_array;
$platform_array{'custom3968'}=\@custom3968_array;
$platform_array{'custom5760'}=\@custom5760_array;
$platform_array{'HsUnigem2'}=\@HsUnigem2_array;
$platform_array{'AtlasCancer'}=\@AtlasCancer_array;
$platform_array{'Atlas'}=\@Atlas_array;
$platform_array{'SAGE'}=\@SAGE_array;

#Once genelists are loaded begin permutations according to comparison list file
my $i;
for ($i = 1; $i <= $permutations; $i++){

  #A file is read specifying what kind of permutations to do.
  #For each comparison result in the comp_list file,
  #pick the correct number of up/down genes randomly from the appropriate array and summarize the overlap for the permutation
  my %summary_up_genes; my %summary_down_genes;

  open (COMPLIST, $comp_lists_file);
  while (<COMPLIST>){
    chomp;
    my @entry = split ("\t",$_);
    my $comp_number = $entry[0];
    my $platform=$entry[1];
    my $num_up_genes=$entry[2];
    my $num_down_genes=$entry[3];
    #print "Analyzing: $comp_number\t$platform\t$num_up_genes\t$num_down_genes\n";
    my @rand_up_genes=&get_rand_array_elements($platform_array{$platform},$num_up_genes);
    my @rand_down_genes=&get_rand_array_elements($platform_array{$platform},$num_down_genes);

    #get a unique list of up/down genes for the comparison
    my %comp_up_genes; my %comp_down_genes;
    foreach my $up_gene(@rand_up_genes){
      #print "$comp_number\t$up_gene\tup\n";
      $comp_up_genes{$up_gene}++; 
    }
    foreach my $down_gene(@rand_down_genes){
      #print "$comp_number\t$down_gene\tdown\n";
      $comp_down_genes{$down_gene}++; #get a unique list of up genes for the comparison
    }

    #Keep count of number of comparisons for which each gene was observed for up or down condition
    foreach my $comp_up_gene (keys %comp_up_genes){
      $summary_up_genes{$comp_up_gene}++;
    }
    foreach my $comp_down_gene (keys %comp_down_genes){
      $summary_down_genes{$comp_down_gene}++;
    }
  }
  close COMPLIST;

  #Summarize the numbers of genes observed 1 or more times
  my %countsummary; my %upcountsummary; my %downcountsummary;
  foreach my $summary_up_gene (keys %summary_up_genes){
    my $gene_count = $summary_up_genes{$summary_up_gene};
    #print "$summary_up_gene found upregulated $gene_count times\n";
    $upcountsummary{$gene_count}++;
    if ($summary_down_genes{$summary_up_gene}){$gene_count=1}; #If this up gene was also found to be a down gene then don't consider it not overlapping (ie. overlap of 1)
    $countsummary{$gene_count}++;
  }
  foreach my $summary_down_gene (keys %summary_down_genes){
    my $gene_count = $summary_down_genes{$summary_down_gene};
    #print "$summary_down_gene found downregulated $gene_count times\n";
    $downcountsummary{$gene_count}++;
    if ($summary_up_genes{$summary_down_gene}){$gene_count=1}; #If this down gene was also found to be an up gene then don't consider it not overlapping (ie. overlap of 1)
    $countsummary{$gene_count}++;
  }

  #Finally print the result
  #print "Overlap among upregulated genes\n";
  #foreach my $upcount (sort{$a<=>$b} keys %upcountsummary){
    #print "$upcount\t$upcountsummary{$upcount}\n";
  #}
  #print "Overlap among downregulated genes\n";
  #foreach my $downcount (sort{$a<=>$b} keys %downcountsummary){
    #print "$downcount\t$downcountsummary{$downcount}\n";
  #}
  #print "Overlap among up or downregulated genes\n";
  my $multigenecount=0;
  my $test_result;
  foreach my $count (sort{$a<=>$b} keys %countsummary){
    if ($count>1){$multigenecount+=$countsummary{$count};}
    #print "$count\t$countsummary{$count}\n";
    print "$countsummary{$count}\t";
    if ($opt_o){print OUTFILE "$countsummary{$count}\t";}
  }
  if ($opt_t){
    if ($multigenecount>=$test_value){
      $test_result='S';
      $sig_result_count++;
    }else{$test_result='NS';}
    print "$test_result($multigenecount vs $test_value)\n";
  }else{print "\n";}
  if ($opt_o){print OUTFILE "\n";}
}
my $pvalue = $sig_result_count/$permutations;
print "pvalue: $pvalue ($sig_result_count/$permutations)\n";
if ($opt_o){print OUTFILE "pvalue: $pvalue ($sig_result_count/$permutations)\n";}
if ($opt_o){close OUTFILE;}
exit;

########################################################
sub get_rand_array_elements{
my $array_ref = shift;
my $num_genes = shift;
my @array=@$array_ref;
my $arraysize=@array;
#print "finding $num_genes random genes from $arraysize total genes\n";

my $n = $num_genes;
my @rand_genes;
my $i;
my %genelist;

for ($i=0; $i<$n; $i++){
  my $arraysize=@array; #each time through loop determine new array size
  my $rand_number = int(rand($arraysize)); #Generate a random integer from to use as array index
  my $gene = $array[$rand_number];#Use random integer to grab an element from array
  if ($opt_u){ #If unique gene option specified
    if ($genelist{$gene}){$i = $i-1;next;}#If this gene has been chosen already, choose again
      $genelist{$gene}++; #Keep track of genes already picked
  }
  push (@rand_genes,$gene); #Put gene in new array of random genes
  splice (@array,$rand_number,1); #Now, remove element from array so that it can't be used again
}
return(@rand_genes);
}

sub readGeneListFiles{
#Files are read into the arrays
open (HG_U95A_v2,$HG_U95A_v2);
while (<HG_U95A_v2>){if ($_=~/\S+/){chomp; push (@HG_U95A_v2_array, $_);}}
close HG_U95A_v2;

open (HG_U133A,$HG_U133A);
while (<HG_U133A>){if ($_=~/\S+/){chomp; push (@HG_U133A_array, $_);}}
close HG_U133A;

open (custom1807,$custom1807);
while (<custom1807>){if ($_=~/\S+/){chomp; push (@custom1807_array, $_);}}
close custom1807;

open (custom27648,$custom27648);
while (<custom27648>){if ($_=~/\S+/){chomp; push (@custom27648_array, $_);}}
close custom27648;

open (custom3968,$custom3968);
while (<custom3968>){if ($_=~/\S+/){chomp; push (@custom3968_array, $_);}}
close custom3968;

open (custom5760,$custom5760);
while (<custom5760>){if ($_=~/\S+/){chomp; push (@custom5760_array, $_);}}
close custom5760;

open (HsUnigem2,$HsUnigem2);
while (<HsUnigem2>){if ($_=~/\S+/){chomp; push (@HsUnigem2_array, $_);}}
close HsUnigem2;

open (AtlasCancer,$AtlasCancer);
while (<AtlasCancer>){if ($_=~/\S+/){chomp; push (@AtlasCancer_array, $_);}}
close AtlasCancer;

open (Atlas,$Atlas);
while (<Atlas>){if ($_=~/\S+/){chomp; push (@Atlas_array, $_);}}
close Atlas;

open (SAGE,$SAGE);
while (<SAGE>){if ($_=~/\S+/){chomp; push (@SAGE_array, $_);}}
close SAGE;
}
