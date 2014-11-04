#!/usr/bin/perl

=head1 NAME

  	GOanalysispercentage.pl

=head1 SYNOPSIS
	
	GOanalysispercentage.pl [randomize]
	
=head1 ARGUMENTS

	
  	randomize		Values: R or r	
  					If specified, randomizes the expression data set before
  	                each GO evaluation iteration.
 
  		
=head1 DESCRIPTION

	The proportion of gene pairs annotated at a specific common GO term for a given gene over 
	neighborhood distances are enumerated and compared against the 'maximum' number of gene pairs 
	that could possibly share a GO term. The maximum number of gene pairs for a given gene at a 
	neighborhood distance k is equal to the value of min(k, the maximum possible number of
	gene pairs sharing a common GO term).
	

=head1 AUTHOR

  	D.L.Fulton
  	Simon Fraser University
  	E-mail: dlfulton@sfu.ca

=cut


use POSIX;
use strict;
use constant VERSION 	=> "GOanalysispercentage 1.0";
use constant DEBUG 		=> 0;
use constant USAGE 		=> "GOanalysispercentage.pl [randomize value: R or r]\n";
 

my @gene1_arr =();
my @gene2_arr = ();
my @corr_arr = ();
my %GeneNeighbourCount = ();
my %EXPR;
my $exprneighborhood = 50; 
my %GOTermcounthash = ();
my %GOTermfreqhash = ();
my %geneassochash = ();
my @indivGOterms = ();
my $exprneighborhood = 50;
my $total_no_genes_inGO = 0;
#-------------------------------------------------------------
#


#Assign standard output file names 
my $GoEvaluationGenePair = "GoEvaluationGenePairPotential_Percentage";
my $GoEvaluationRankSumm = "GoEvaluationRankSummPotential_Percentage";

my $randomize_parm = $ARGV[0];
if ($randomize_parm && ($randomize_parm ne "R" && $randomize_parm ne "r") ) 
    {die ("\n ERROR: " .  USAGE . "\n");}
    

#-------------- Common Pairs DATASETS -------------------------------------------------------
#my $common_genepairs = "/home/sage/clustering/matrix/affy_micro_sage_comp/040407/results/for_GO/10sage_100micro_100affy/10sage_100micro_100affy_common_gene_pairs";
#my $common_genepairs = "/home/sage/clustering/matrix/affy_micro_sage_comp/040407/results/for_GO/25sage_25micro_25affy/25sage_25micro_25affy_common_gene_pairs";
#my $common_genepairs = "/home/sage/clustering/matrix/affy_micro_sage_comp/040407/results/for_GO/10sage_10micro_10affy/10sage_10micro_10affy_common_gene_pairs";
#my $common_genepairs = "/home/sage/clustering/matrix/affy_micro_sage_comp/040407/results/for_GO/100sage_100micro_100affy/100sage_100micro_100affy_common_gene_pairs";
#-------------- AFFY DATASETS -------------------------------------------------------
#my $exprresults = "/home/sage/clustering/matrix/affy_micro_sage_comp/040407/results/for_GO/normalized_affy/10sage_100micro_100affy/affy_gt100_common.txt";
#my $exprresults = "/home/sage/clustering/matrix/affy_micro_sage_comp/040407/results/for_GO/normalized_affy/25sage_25micro_25affy/affy_gt25_common.txt";
#my $exprresults = "/home/sage/clustering/matrix/affy_micro_sage_comp/040407/results/for_GO/normalized_affy/10sage_10micro_10affy/affy_gt10_common.txt";
#my $exprresults = "/home/sage/clustering/matrix/affy_micro_sage_comp/040407/results/for_GO/normalized_affy/100sage_100micro_100affy/affy_gt100_common.txt";
my $exprresults = "/home/sage/clustering/matrix/affy_micro_sage_comp/040407/results/for_GO/23sage_28micro_95affy/affy_gt95_common.txt";

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

#--------------------------------------------------------------------------------------
 
print "\nLoading Correlation results into hash\n" if DEBUG;
print "Expression Data File Being Processed: $exprresults\n" if DEBUG;
open (EXPRRESULTS, $exprresults) or die "can't open $exprresults\n";
my $exprcount = 0;
my $x = 0;
print "Randomize parm->$randomize_parm\n" if DEBUG;
while (<EXPRRESULTS>){
  	if ($_=~/^(\S+)\s+(\S+)\s+(\S+)/){     
    	$exprcount++;
       	my $gene1 = $1;
       	my $gene2 = $2;
       	my $r = $3;                         
   		if ($randomize_parm eq 'r' || $randomize_parm eq 'R') 
      	{ 
       		$gene1_arr[$x] =  $gene1;
       		$gene2_arr[$x] =  $gene2;
       		$corr_arr[$x] =  $r;
       		#print "gene1->$gene1_arr[$x], gene2-> $gene2_arr[$x], corr->$corr_arr[$x]\r";
       		print "Array Load: gene1->$gene1;, gene2-> $gene2, corr->$r\r" if DEBUG;

       
       		$x++;
       		}
    	else {
       		print "EXPR results loaded->$exprcount EXPR gene1->$gene1, gene2->$gene2, corr->$r\r" if DEBUG;
       
         	$EXPR{$gene1}{$gene2}= $r;
       		$EXPR{$gene2}{$gene1}= $r;
      	}

  	}
}
close(EXPRRESULTS);
print "\nRandomize parm->$randomize_parm\n";

if ($randomize_parm eq 'r' || $randomize_parm eq 'R') {
   for  (my $j = 0; $j < $exprcount; $j++) {
       my $r = $corr_arr[rand @corr_arr];  # randomly pick an element from array
       print "Rand Array->Hash: gene1->$gene1_arr[$j], gene2->$gene2_arr[$j], correlation->$r \r" if DEBUG;
       $EXPR{$gene1_arr[$j]}{$gene2_arr[$j]} = $r;
       $EXPR{$gene2_arr[$j]}{$gene1_arr[$j]} = $r;
   } #end for
} # end if
 

#--------------------------------------------------------------------------------------------
# Hash the GO Annotation data                                               
 
open(TARGET, "PopulationGeneAssoc") ||   
	die ("Can't open PopulationGeneAssoc: $!\n");
     
my $j = 0;

while(<TARGET>) {            
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
#-------------------------------------------------------------------------------------
# Compute the number of genes that share a specific GO term for each gene. This will
# contribute to the denominator in the percentage in GO metric.
#
  
 foreach my $gene1 (sort {$a <=> $b} keys %EXPR){
  	if (defined($geneassochash{$gene1})) {  # check to see if gene is in GO
    my $j = 0;
    my $neighbor = 0;
    my $commontermid = 0;
       
    
    foreach my $gene2 (sort {$EXPR{$gene1}{$b} <=> $EXPR{$gene1}{$a}} #sort columns
					(keys(%{$EXPR{$gene1}}))){
    	if (defined($geneassochash{$gene2})) { 
        	$j++;
        	if ($j <= $exprneighborhood) {
          		($neighbor, $commontermid) =  &Nodeneighbors($gene1, $gene2,\%geneassochash);
          		if ($neighbor == 1) { 
            		$GeneNeighbourCount{$gene1}++;
              
          		} # end if
        	} # end if
        	else {last;}
     	} # end if defined
   } # end for
   
   print "Counting GO Node Neighbors for LocusLinkID->$gene1 Count->$GeneNeighbourCount{$gene1}\r" if DEBUG;
} # end if defined

} # end for

 
    
#-----------------------------------------------------------------

 
open(NF, ">$GoEvaluationGenePair")  || 
	die ("Cant't open GoEvaluationGenePair for writing: $!\n");
my @ranksummary = (); 
my @ranksummarydenominator = (); 
for(my $k = 1; $k <= $exprneighborhood ; $k++)
    {$ranksummary[$k] = 0;
     $ranksummarydenominator[$k] = 0;}
  
 foreach my $gene1 (sort {$a <=> $b} keys %EXPR){
 	if (defined($geneassochash{$gene1})) {  # check to see if gene is in GO
  		my $i = 0;
  		my $pvalue = 0;
  		my $neighbor = 0;
  		my $commontermid = 0;   
  		my $included_count_in_denominator = 0;
    	foreach my $gene2 (sort {$EXPR{$gene1}{$b} <=> $EXPR{$gene1}{$a}} #sort columns
					(keys(%{$EXPR{$gene1}}))){
      		if (defined($geneassochash{$gene2})) { 
        		print "Processing Gene1: $gene1  Gene2 $gene2\r" if DEBUG;
        		$i++;
         
        		if ($i <= $exprneighborhood)
          			{if ($i <= $GeneNeighbourCount{$gene1}) {
              			$ranksummarydenominator[$i] = $ranksummarydenominator[$i] + $GeneNeighbourCount{$gene1};  
              			($neighbor, $commontermid) =  &Nodeneighbors($gene1, $gene2,\%geneassochash);
              
              			if ($neighbor == 1)
                 		{ 
                 			$pvalue = &ProbabilityCalc($commontermid, \%GOTermcounthash);
                 			#printing gene1, gene2, corr, in GO 1/0, GO Node ID, p-value for node, rank summary 
                 			print(NF join("\t",$gene1, $gene2, $EXPR{$gene1}{$gene2}, "1",$commontermid, $pvalue, $i, "\n"));
                 			$ranksummary[$i]++;                   
                 		} # end if
              			else
                 		{ 
                  			print(NF join("\t",$gene1, $gene2, $EXPR{$gene1}{$gene2}, "0"," ","0", $i, "\n"));}
          			} # end if
         		} # end if
        		else
          			{last;}    
       		} # end if define gene2
     	} # end foreach gene2
 	} # end if define gene1
 } # end foreach gene1

close(NF);

# Write out the ranksummary %  

open(NF, ">$GoEvaluationRankSumm")  || 
	die ("Can't open GoEvaluationRankSummfor writing: $!\n");
for(my $k = 1; $k <= $exprneighborhood ; $k++)
    {print NF  "$ranksummary[$k] ";}    
print NF "\n";
for(my $k = 1; $k <= $exprneighborhood ; $k++)
    {print NF  "$ranksummarydenominator[$k]  ";}   
print NF "\n";
for(my $k = 1; $k <= $exprneighborhood ; $k++)
    { my $percent = 0;
 	if ($ranksummarydenominator[$k] != 0) {
    	$percent = sprintf("%.2f", ($ranksummary[$k]/$ranksummarydenominator[$k]) *100);}
    	print NF  "$percent ";}    
close(NF);
     	   	 
exit 0;




#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ SUBROUTINES @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
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
