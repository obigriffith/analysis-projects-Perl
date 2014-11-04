#!/usr/local/bin/perl


=head1 NAME

  	makePopGene_set.pl

=head1 SYNOPSIS
	
	makePopGene_set.pl
	
=head1 ARGUMENTS

	
	N/A
  		
=head1 DESCRIPTION

	Populates a file with the set of genes (locuslink ids) that are found in common 
	across the platform datasets. This set of genes is used to extract the GO annotations.

=head1 AUTHOR

  	D.L.Fulton
  	Simon Fraser University
  	E-mail: dlfulton@sfu.ca

=cut
 

use POSIX;
use strict; 
use constant VERSION 	=> "makePopGene_set1.0";
use constant DEBUG 		=> 0;
use constant USAGE 		=> "makePopGene_set.pl";

#-------------- Common Pairs DATASETS -------------------------------------------------------
my $common_genepairs = "/home/sage/clustering/matrix/affy_micro_sage_comp/040407/results/for_GO/23sage_28micro_95affy/common_gene_pairs.txt";
#my $common_genepairs = "/home/sage/clustering/matrix/affy_micro_sage_comp/040407/results/for_GO/25sage_25micro_25affy/25sage_25micro_25affy_common_gene_pairs";
#my $common_genepairs = "/home/sage/clustering/matrix/affy_micro_sage_comp/040407/results/for_GO/10sage_10micro_10affy/10sage_10micro_10affy_common_gene_pairs";
#my $common_genepairs = "/home/sage/clustering/matrix/affy_micro_sage_comp/040407/results/for_GO/100sage_100micro_100affy/100sage_100micro_100affy_common_gene_pairs";
#-------------------------------------------------------------------------------------------

&main();
exit 0;

#--------------------------------------------------------------------------------------------
sub main() {

my %GENEPAIRS;
 
 
print "\nLoading Population Gene Set\n" if DEBUG;
print "\nProcessing Input File: $common_genepairs \n" if DEBUG;
open (COMMON_GENEPAIRS, $common_genepairs ) or die "can't open $common_genepairs \n";
my $genepaircount = 0;

while (<COMMON_GENEPAIRS>){
 	if ($_=~/^(\S+)\s+(\S+)/){
    	$genepaircount++;
    	print "GenePair results loaded: $genepaircount\r";
    	my $gene1 = $1;
    	my $gene2 = $2;
                            
    	$GENEPAIRS{$gene1}{$gene2}= 0;
    	$GENEPAIRS{$gene2}{$gene1}= 0;
  	}
}
close(COMMON_GENEPAIRS);

#### Create the population file  

open(PG, ">PopulationGeneSet")  || 
	die ("Can't open PopulationGeneSet to write to: $!\n");
foreach my $gene1 (sort {$a <=> $b} keys %GENEPAIRS){
 	{print(PG ($gene1, "\n"));}
}
close(PG);
}
#-------------------------------------------------------------------------------------------------------
