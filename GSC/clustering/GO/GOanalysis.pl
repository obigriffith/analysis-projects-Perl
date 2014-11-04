#!/usr/bin/perl

=head1 NAME

  	GOanalysis.pl

=head1 SYNOPSIS
	
	GOanalysis.pl [randomize] [iterations]
	
=head1 ARGUMENTS

	
  	randomize		Values: R or r	
  					If specified, randomizes the expression data set before
  	                each GO evaluation iteration.
 	iterations		Value: positive integer
  					Valid only with the randomization parameter. 
  					Specifies the number of GO evaluation iterations
  					Default value is 1
  		
=head1 DESCRIPTION

	Enumerates the top K ranked pairwise gene correlations for each gene against 
	the Gene Ontology database. If a gene pair is found on the same GO node
	a rank accumulator is incremented.

=head1 AUTHOR

  	D.L.Fulton
  	Simon Fraser University
  	E-mail: dlfulton@sfu.ca

=cut


use POSIX;
use strict;
use constant VERSION 	=> "GOanalysis 1.0";
use constant DEBUG 		=> 0;
use constant USAGE 		=> "GOanalysis.pl [randomize value: R or r] [randomize iterations value: positive integer] \n";
 
 
my @gene1_arr =();
my @gene2_arr = ();
my @corr_arr = ();
 
my %GOTermcounthash = ();
my %GOTermfreqhash = ();
my %geneassochash = ();
my @indivGOterms = ();
my $exprneighborhood = 50;
my $total_no_genes_inGO = 0;
 

    
#---- DATASETS ------------------------------------------------------------------------
#-------------- Common Pairs DATASETS -------------------------------------------------------
#my $common_genepairs = "/home/sage/clustering/matrix/affy_micro_sage_comp/040407/results/for_GO/10sage_100micro_100affy/10sage_100micro_100affy_common_gene_pairs";
#my $common_genepairs = "/home/sage/clustering/matrix/affy_micro_sage_comp/040407/results/for_GO/25sage_25micro_25affy/25sage_25micro_25affy_common_gene_pairs";
#my $common_genepairs = "/home/sage/clustering/matrix/affy_micro_sage_comp/040407/results/for_GO/10sage_10micro_10affy/10sage_10micro_10affy_common_gene_pairs";
#my $common_genepairs = "/home/sage/clustering/matrix/affy_micro_sage_comp/040407/results/for_GO/100sage_100micro_100affy/100sage_100micro_100affy_common_gene_pairs";
#my $common_genepairs = "/home/sage/clustering/matrix/affy_micro_sage_comp/040407/results/for_GO/23sage_28micro_95affy/common_gene_pairs.txt";

#-------------- AFFY DATASETS -------------------------------------------------------
#my $exprresults = "/home/sage/clustering/matrix/affy_micro_sage_comp/040407/results/for_GO/normalized_affy/10sage_100micro_100affy/affy_gt100_common.txt";
#my $exprresults = "/home/sage/clustering/matrix/affy_micro_sage_comp/040407/results/for_GO/normalized_affy/25sage_25micro_25affy/affy_gt25_common.txt";
#my $exprresults = "/home/sage/clustering/matrix/affy_micro_sage_comp/040407/results/for_GO/normalized_affy/10sage_10micro_10affy/affy_gt10_common.txt";
#my $exprresults = "/home/sage/clustering/matrix/affy_micro_sage_comp/040407/results/for_GO/normalized_affy/100sage_100micro_100affy/affy_gt100_common.txt";
#my $exprresults = "/home/sage/clustering/matrix/affy_micro_sage_comp/040407/results/for_GO/23sage_28micro_95affy/affy_gt95_common.txt";
my $exprresults = "/home/sage/clustering/matrix/affy_micro_sage_comp/040407/results/for_coexpression_db/affy_only_gt100.txt";

#-------------- SAGE DATASETS ------------------------------------------------------
#my $exprresults = "/home/sage/clustering/matrix/affy_micro_sage_comp/040407/results/for_GO/normalized_affy/10sage_100micro_100affy/sage_gt10_common.txt";
#my $exprresults = "/home/sage/clustering/matrix/affy_micro_sage_comp/040407/results/for_GO/normalized_affy/25sage_25micro_25affy/sage_gt25_common.txt";
#my $exprresults = "/home/sage/clustering/matrix/affy_micro_sage_comp/040407/results/for_GO/normalized_affy/10sage_10micro_10affy/sage_gt10_common.txt";
#my $exprresults = "/home/sage/clustering/matrix/affy_micro_sage_comp/040407/results/for_GO/normalized_affy/100sage_100micro_100affy/sage_gt100_common.txt";
#my $exprresults = "/home/sage/clustering/matrix/affy_micro_sage_comp/040407/results/for_GO/23sage_28micro_95affy/sage_gt23_common.txt";

#-------------- cDNA DATASETS ------------------------------------------------------
#my $exprresults = "/home/sage/clustering/matrix/affy_micro_sage_comp/040407/results/for_GO/normalized_affy/10sage_100micro_100affy/micro_gt100_common.txt";
#my $exprresults = "/home/sage/clustering/matrix/affy_micro_sage_comp/040407/results/for_GO/normalized_affy/25sage_25micro_25affy/micro_gt25_common.txt";
#my $exprresults = "/home/sage/clustering/matrix/affy_micro_sage_comp/040407/results/for_GO/normalized_affy/10sage_10micro_10affy/micro_gt10_common.txt";
#my $exprresults = "/home/sage/clustering/matrix/affy_micro_sage_comp/040407/results/for_GO/normalized_affy/100sage_100micro_100affy/micro_gt100_common.txt";
#my $exprresults = "/home/sage/clustering/matrix/affy_micro_sage_comp/040407/results/for_GO/23sage_28micro_95affy/micro_gt28_common.txt";


#Assign standard output file names
my $GoEvaluationGenePair = "GoEvaluationGenePair";
my $GoEvaluationRankSumm = "GoEvaluationRankSumm";

#Process the arguments
my $randomize_parm = $ARGV[0];
my $iterations = $ARGV[1];

if ($randomize_parm && ($randomize_parm ne "R" && $randomize_parm ne "r") ) 
    {die ("\n ERROR: " .  USAGE . "\n");}
    
if (!$iterations) {
    $iterations = 1;
}
print "\nRandomize_parm->$randomize_parm\n";
print "Iterations selected->$iterations \n";
#--------------------------------------------------------------------------------------------
# Hash the GO Annotation data                                               
 
open(TARGET, "PopulationGeneAssoc") ||   
	die ("Can't open PopulationGeneAssoc: $!\n");
     
my $j = 0;

while(<TARGET>) {           # while new line, for each line evaluate
	chomp;
    if (/^([^\t]*)\t([^\t]*)$/) {
	    my $genename = $1;
        chop $genename;
        my $annotation = $2;  
        $total_no_genes_inGO++;        
	    $geneassochash{$genename} = $annotation;
        #split $annotation using ; as a delimiter
        my @GeneGOterms = split(/;/,$annotation);
	    my $length_of_GeneGOterms_array = $#GeneGOterms;  
	    
        # Here we create a columnar list of individual GO terms
        # 
	    for(my $k=0; $k<=$length_of_GeneGOterms_array; $k++) { 
        	$GeneGOterms[$k] =~ /(\S+)\s/;
        	$indivGOterms[$j] = $1;
            $j++;
                   
	    } # end for
    
	} #end if
} #end while
print "Done parsing PopulationGeneAssoc file\n" if DEBUG;
close(TARGET);

print "Number of population genes in GO: $total_no_genes_inGO\n" if DEBUG;
my $arrlen = $#indivGOterms;
 
# Make the list of individiual GO terms unique and count the number of genes annotated
# to a GO term
&uniqify(\%GOTermcounthash, \%GOTermfreqhash, @indivGOterms);
 
#--------------------------------------------------------------------------------------
my %EXPR = ();
$exprneighborhood = 50;

open(RF, ">$GoEvaluationRankSumm")  || 
	die ("Can't open GoEvaluationRankSumm for writing: $!\n");

print "\nLoading Correlation results into hash\n" if DEBUG;
print "\nProcessing Input File: $exprresults\n" if DEBUG;
open (EXPRRESULTS, $exprresults) or die "can't open $exprresults\n";
my $exprcount = 0;
my $x = 0;
 
while (<EXPRRESULTS>){
  	if ($_=~/^(\S+)\s+(\S+)\s+(\S+)/){     
       	$exprcount++;
       	my $gene1 = $1;
       	my $gene2 = $2;
       	my $r = $3;                         
   		if ($randomize_parm eq "r" || $randomize_parm eq "R") 
      		{ 
       		$gene1_arr[$x] =  $gene1;
       		$gene2_arr[$x] =  $gene2;
       		$corr_arr[$x] =  $r;
       		print "Array Load: gene1->$gene1;, gene2->$gene2, corr->$r\r" if DEBUG;
       		$x++;
       		}
    	else {
       		print "EXPR results loaded: $exprcount gene1->$1, gene2-> $2, corr->$3\r" if DEBUG;
       		$EXPR{$gene1}{$gene2}= $r;
       		$EXPR{$gene2}{$gene1}= $r;
      		}

  	}
}
close(EXPRRESULTS);
 
for (my $v = 0; $v < $iterations; $v++) { 
    

	if ($randomize_parm eq "r" || $randomize_parm eq "R") {
   		for  (my $j = 0; $j < $exprcount; $j++) {
       	my $r = $corr_arr[rand @corr_arr];  # randomly pick an element from array
       	###print "Rand Array->Hash: gene1->$gene1_arr[$j], gene2->$gene2_arr[$j], correlation->$r \r";
       	$EXPR{$gene1_arr[$j]}{$gene2_arr[$j]} = $r;
       	$EXPR{$gene2_arr[$j]}{$gene1_arr[$j]} = $r;
   		} #end for
	}  
 	print "Iteration Step->$v\n" if DEBUG;
#     
#-----------------------------------------------------------------
# Step across correlation-sorted rows to find a gene's nearest k neighborhors
# and enumerate their placement on a GO Node. If they fall on the same node the GO placement 
# counter for rank K is incremented and a p-value is calculated.


	if (!$randomize_parm) {
		open(DF, ">$GoEvaluationGenePair")  || 
		die ("Cant't open GoEvaluationGenePair for writing: $!\n");
	}
	my @ranksummary = (); 
	for(my $k = 1; $k <= $exprneighborhood ; $k++)
    	{$ranksummary[$k] = 0;}
    	
 	foreach my $gene1 (sort {$a <=> $b} keys %EXPR){
  		if (defined($geneassochash{$gene1})) {  # check to see if gene is in GO
  			my $i = 0;
  			my $pvalue = 0;
  			my $neighbor = 0;
  			my $commontermid = 0;       
    		foreach my $gene2 	(sort {$EXPR{$gene1}{$b} <=> $EXPR{$gene1}{$a}} #sort columns
								(keys(%{$EXPR{$gene1}}))){
    			if (defined($geneassochash{$gene2})) { 
      				print "Processing Gene1: $gene1  Gene2 $gene2\r" if DEBUG;
        			$i++;       
        				if ($i <= $exprneighborhood)
          				{
           					($neighbor, $commontermid) =  &Nodeneighbors($gene1, $gene2,\%geneassochash);          
           					if ($neighbor == 1) {
              					$pvalue = &ProbabilityCalc($commontermid, \%GOTermcounthash);
              					#printing gene1, gene2, corr, in GO 1/0, GO Node ID, p-value for node, rank summary 
              					print(DF join("\t",$gene1, $gene2, $EXPR{$gene1}{$gene2}, "1",$commontermid, $pvalue, $i, "\n")) if !$randomize_parm;
              					$ranksummary[$i]++;  
              				} 
           					else {
               					print(DF join("\t",$gene1, $gene2, $EXPR{$gene1}{$gene2}, "0"," ","0", $i, "\n")) if !$randomize_parm;
              				}
          				} # end if
        				else {
          					last;
          				}    
    			} # end if define gene2
     		} # end foreach gene2
   		} # end if define gene1
 	} # end foreach gene1

	# Write out the GO evaluation ranked summary

	for(my $k = 1; $k <= $exprneighborhood ; $k++)
    	{print RF  "$ranksummary[$k] ";}   
	print RF "\n";

   
} # end for $v iterations

if (!$randomize_parm) {
	close(DF);
}
close(RF);
     	   	 
exit 0;




#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ SUBROUTINES @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
# Hash the terms to precipitate unique entries and count the GO node annotation occurences
sub uniqify (\%\%@) {
    
	#input is the array of multiple occurences of GO terms
    my $hash1ref = shift ;
    my $hash2ref = shift ; 
    my @localarray = @_;
    my $arraylen = $#localarray;
    my $GOTermcounthash = %$hash1ref;
    my $GOTermfreqhash = %$hash2ref;
    
    foreach my $GOterm (@localarray) {           
        $GOTermcounthash{$GOterm}++;     
        print " GOterm->$GOterm \t count->$GOTermcounthash{$GOterm} \n" if DEBUG;
    }
   
    foreach my $GOterm (keys %GOTermcounthash) {
         print "GOterm->$GOterm \t count->$GOTermcounthash{$GOterm} \n" if DEBUG;  
         $GOTermfreqhash{$GOterm} = $GOTermcounthash{$GOterm}/$total_no_genes_inGO;
         print "GOterm->$GOterm \t freq->$GOTermfreqhash{$GOterm} \n" if DEBUG;
    }
   
}

#-----------------------------------------------------------------------------------------
# Check to see whether two gene are neighbors on a GO node. 
sub Nodeneighbors($$\%) {
   
    my $gene1 = shift @_;
    my $gene2 = shift @_;
    my $href = shift @_;
    my $True = 0;
    my $minfreq = 1;
    my $Termid = " ";
    my $GOterm1;
    my $GOterm2;
    my $GOtermG1;
    my $GOtermG2;
    my $g1assoc = $href->{$gene1};
    my $g2assoc = $href->{$gene2};
    my @G1array = split(/;/,$g1assoc); 
    my @G2array = split(/;/,$g2assoc);

	foreach $GOterm1 (@G1array) {
    	$GOterm1 =~ /(\S+)\s(.*)/;
    	$GOtermG1 = $1;
        foreach $GOterm2 (@G2array) {
        	$GOterm2 =~ /(\S+)\s(.*)/;
        	$GOtermG2 = $1; 
            if ($GOtermG2 eq $GOtermG1) 
                {$True = 1;
                 # if there is more than one common GO term for these two genes,
                 # select the GO term with the lowest frequency of genes annotated to it
                 if($GOTermfreqhash{$GOtermG1} < $minfreq)
                    {$Termid = $GOtermG1;
                     $minfreq =  $GOTermfreqhash{$GOtermG1};}
            }  # end if
     	} # end foreach
 	} # end foreach
 return ($True, $Termid);
}            
    
#-----------------------------------------------------------------------------------------
# Compute a hypergeomtric probability of two genes being selected that fall on the same GO node
# f/N x f-1/N-1 with a Bonferroni correction (x2) for multiple testing
sub ProbabilityCalc {

  my $p_value = 0;
  my ($Termid) = shift @_;
  my $GOTermcounthref = shift @_;
  my $termcount = $GOTermcounthref->{$Termid};
  $p_value =   (($termcount/$total_no_genes_inGO) *
		($termcount-1/$total_no_genes_inGO-1)) * 2;
  if ($p_value > 1)
    {$p_value = 1;}
  return $p_value;
}
