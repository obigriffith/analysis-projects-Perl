#!/usr/bin/perl
 
=head1 NAME

  	GOanalysisBestMatch.pl

=head1 SYNOPSIS
	
	GOanalysisBestMatch.pl
	
=head1 ARGUMENTS

	N/A 
  	
=head1 DESCRIPTION
	
	Computes the sum of correlation values of all gene pairs across 3 expression platforms 
	and sorts them in descending order to obtain the maximal sum of correlation values. 
	
	
=head1 AUTHOR

  	D.L.Fulton
  	Simon Fraser University
  	E-mail: dlfulton@sfu.ca

=cut


use POSIX;
use strict; 
use constant VERSION 	=> "GOanalysisBestMatch 1.0";
use constant DEBUG 		=> 0;
use constant USAGE 		=> "GOanalysisBestMatch.pl";
 
 
my @gene1_arr =();
my @gene2_arr = ();
my @corr_arr = ();
 
my %GOTermcounthash = ();
my %GOTermfreqhash = ();
my %geneassochash = ();
my @indivGOterms = ();
my $exprneighborhood = 50;
my $total_no_genes_inGO = 0;
#-------------------------------------------------------------
#

#Use standard output file names
my $GoEvaluationGenePair = "GoEvaluationGenePair_BestMatch";
 
my $GoEvaluationRankSumm = "GoEvaluationRankSumm_BestMatch";

 
#---- DATASETS ------------------------------------------------------------------------
#my $exprresults = "/home/egarland/Projects/SAGE/clustering/matrix/affy_micro_sage_comp/old/" . 
                   "results/final_micro_results_common2all.txt";  
#my $exprresults = "/home/egarland/Projects/SAGE/clustering/matrix/affy_micro_sage_comp/old/" . 
                   "results/final_AFFY_results_humanGEO_U133A_common2all.txt";
#my $exprresults = "/home/egarland/Projects/SAGE/clustering/matrix/affy_micro_sage_comp/old/" . 
                   "results/final_SAGE_nofilter_log_freqs_results_common2all.txt";
 
#my $exprresults = "SAGE_GEO_noplus1_nulls_vs_micro_bestmatches_n10.txt.genelist"; #sage/micro 
#my $exprresults = "AFFY_GEO_normalized_ln_vs_micro_bestmatches_n10.txt.genelist";  #affy/micro
#my $exprresults = "AFFY_GEO_normalized_ln_vs_SAGE_GEO_noplus1_nulls_bestmatches_n10.txt.genelist"; #affy/sage 

#my $exprresults = "SAGE_GEO_noplus1_nulls_vs_micro_bestmatches_n10_random.txt.genelist";   #sage/micro 
#my $exprresults = "AFFY_GEO_normalized_ln_vs_micro_bestmatches_n10_random.txt.genelist";  #affy/micro
my $exprresults = " AFFY_GEO_normalized_ln_vs_SAGE_GEO_noplus1_nulls_bestmatches_n10_random.txt.genelist"; #affysage 

#--------------------------------------------------------------------------------------



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
    
#-----------------------------------------------------------------

 
open(NF, ">$GoEvaluationGenePair")  || 
	die ("Can't open GoEvaluationGenePair for writing: $!\n");
my @ranksummary = (); 
my $GenePairs_NotInGO = 0;
my $GenePairs_InGO = 0;
my $GenePairs_withGoTerm = 0;
my %Gene_NOGO = ();
my %Gene_INGO = ();
my $GenePairCount = 0;
for(my $k = 1; $k <= $exprneighborhood ; $k++)
	{$ranksummary[$k] = 0;}
  
open (EXPRRESULTS, $exprresults) or die "can't open $exprresults\n";
print "\nExpression Data File Being Processed: $exprresults\n";    
while (<EXPRRESULTS>){
  	if ($_=~/^(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)/){     
    	my $rank = $1;
       	my $gene1 = $2;
       	my $gene2 = $3;
       	my $r1 = $4;
       	my $r2 = $5; 
   		print "Rank->$rank, Gene1->$gene1, Gene2->$gene2, Corr1->$r1, Corr2->$r2\n" if DEBUG;
   
 		if ($rank <= $exprneighborhood) {        
    		$GenePairCount++;                 
  			if (defined($geneassochash{$gene1})) {  # check to see if gene is in GO
  
  				my $i = 0;
  				my $pvalue = 0;
  				my $neighbor = 0;
  				my $commontermid = 0;   
    
    
      			if (defined($geneassochash{$gene2})) { 
       
           			$Gene_INGO{$gene2} = $gene1;
           			$GenePairs_InGO++; 
           			($neighbor, $commontermid) =  &Nodeneighbors($gene1, $gene2,\%geneassochash);
           			#print "Gene1: $gene1  Gene2 $gene2 \n";
           			#DLF print "corr->$EXPR{$gene1}{$gene2}\n";
           			if ($neighbor == 1)
              		{ 
              			print "Gene1: $gene1  Gene2 $gene2 \r";
              			$pvalue = &ProbabilityCalc($commontermid, \%GOTermcounthash);
              			#printing gene1, gene2, corr, in GO 1/0, GO Node ID, p-value for node, rank summary 
              			print(NF join("\t",$gene1, $gene2, $r1, $r2, "1",$commontermid, $pvalue, $rank, "\n"));
              			$ranksummary[$rank]++; 
              			$GenePairs_withGoTerm++;
              		} # end if
           			else
              			{print(NF join("\t",$gene1, $gene2, $r1, $r2, "0"," ", " ", $rank, "\n"));}			
     
        		} # end if define gene2
        		else {
        			$Gene_NOGO{$gene2} = $gene1;
              		$GenePairs_NotInGO++;}
   			} # end if define gene1
    		else {
    			$Gene_NOGO{$gene1} = $gene2;
          		$GenePairs_NotInGO++;}
  		} # end if rank within neighborhood
 	} # end if
} # end while
 

close(NF);

# Write out the GO evaluation ranksummary 

open(NF, ">$GoEvaluationRankSumm")  || 
	die ("Can't open GoEvaluationRankSumm for writing: $!\n");
for(my $k = 1; $k <= $exprneighborhood ; $k++)
    {print NF  "$ranksummary[$k] ";}   
close(NF);
 
open(NX, ">BestMatch_NotInGO")  ||     
	die ("Can't open BestMatch_NotInGO for writing: $!\n");
foreach my $gene1 (sort {$a <=> $b} keys %Gene_NOGO)
    {print NX  "$gene1 \t $Gene_NOGO{$gene1}\n";}    	

# Save a couple of statistics about this run
print NX "\nFile Processed: $exprresults\n";   
print NX "Best Match Gene Pairs In GO: $GenePairs_InGO within neighborhood size: $exprneighborhood \n"; 
print NX "Best Match Gene Pairs Not In GO: $GenePairs_NotInGO within neighborhood size: $exprneighborhood \n";
print NX "Best Match TotalGene Pairs are: $GenePairCount within neighborhood size: $exprneighborhood \n";
print NX "Best Match Gene Pairs With Common Go Terms: $GenePairs_withGoTerm\n within neighborhood size: $exprneighborhood \n"; 

close(NX);
# Save the genes that were found in GO
open(NX, ">BestMatch_InGO")  ||     
	die ("Can't open BestMatch_InGO for writing: $!\n");
foreach my $gene1 (sort {$a <=> $b} keys %Gene_INGO)
    {print NX  "$gene1 \t $Gene_INGO{$gene1}\n";}    	
close(NX);
	 
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
