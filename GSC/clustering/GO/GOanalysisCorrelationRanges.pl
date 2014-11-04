#!/usr/bin/perl

=head1 NAME

  	GO_analysisCorreltionRanges.pl 
  	
=head1 SYNOPSIS
	
	GO_analysisCorreltionRanges.pl [randomize] [iterations]
	
=head1 ARGUMENTS

	
  	randomize		Values: R or r	
  					If specified, randomizes the expression data set before
  	                each GO evaluation iteration.
 	iterations		Value: positive integer
  					Valid only with the randomization parameter. 
  					Specifies the number of GO evaluation iterations
  					Default value is 1
  		
=head1 DESCRIPTION

	Enumerates the number of gene pairs that share a GO node
	within each 0.10 correlation range partition.

=head1 AUTHOR

  	D.L.Fulton
  	Simon Fraser University
  	E-mail: dlfulton@sfu.ca

=cut
 
 
use POSIX;
use strict; 
use Getopt::Std;
getopts("f:o:c:i:r");
use vars qw($opt_o $opt_f $opt_c $opt_r $opt_i);
use constant VERSION 	=> "GOanalysisCorrelationRanges 1.0";
use constant DEBUG 		=> 0;
use constant USAGE 		=> "GOanalysisCorrelationRanges.pl [randomize value: R or r] [randomize iterations value: positive integer] \n";


my @gene1_arr =();
my @gene2_arr = ();
my @corr_arr = ();
 
my %GOTermcounthash = ();
my %GOTermfreqhash = ();
my %geneassochash = ();
my @indivGOterms = ();
my $total_no_genes_inGO = 0;

my $lower = 1; #upper and lower determine the range of scores to report summary for (currently only allows 0.1 increments)
my $upper = 35;
my $minimum = 0; #sets a minimum score threshold (eg. in case you don't want to consider -ve Pearson values).

#------------------------------------- DATASETS --------------------------------------------------
#--------------- Common Pairs DATASETS ----------------------------------------------
#my $common_genepairs = "/home/sage/clustering/matrix/affy_micro_sage_comp/040407/results/for_GO/10sage_100micro_100affy/10sage_100micro_100affy_common_gene_pairs";
#my $common_genepairs = "/home/sage/clustering/matrix/affy_micro_sage_comp/040407/results/for_GO/25sage_25micro_25affy/25sage_25micro_25affy_common_gene_pairs";
#my $common_genepairs = "/home/sage/clustering/matrix/affy_micro_sage_comp/040407/results/for_GO/10sage_10micro_10affy/10sage_10micro_10affy_common_gene_pairs";
#my $common_genepairs = "/home/sage/clustering/matrix/affy_micro_sage_comp/040407/results/for_GO/100sage_100micro_100affy/100sage_100micro_100affy_common_gene_pairs";
#-------------- AFFY DATASETS -------------------------------------------------------
#my $exprresults = "/home/sage/clustering/matrix/affy_micro_sage_comp/040407/results/for_GO/normalized_affy/10sage_100micro_100affy/affy_gt100_common.txt";
#my $exprresults = "/home/sage/clustering/matrix/affy_micro_sage_comp/040407/results/for_GO/normalized_affy/25sage_25micro_25affy/affy_gt25_common.txt";
#my $exprresults = "/home/sage/clustering/matrix/affy_micro_sage_comp/040407/results/for_GO/normalized_affy/10sage_10micro_10affy/affy_gt10_common.txt";
#my $exprresults = "/home/sage/clustering/matrix/affy_micro_sage_comp/040407/results/for_GO/normalized_affy/100sage_100micro_100affy/affy_gt100_common.txt";
#my $exprresults = "/home/sage/clustering/matrix/affy_micro_sage_comp/040407/results/for_GO/23sage_28micro_95affy/affy_gt95_common.txt";
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
my ($exprresults, $GoEvaluationCorrelationRanges, $commonterms);
$exprresults = $opt_f;
$GoEvaluationCorrelationRanges = $opt_o;
if ($opt_c){$commonterms = $opt_c;}
#my $GoEvaluationCorrelationRanges = "GoEvaluationCorrelationRanges";

#Process the arguments
my $iterations;
if ($opt_i){$iterations = $opt_i;}else{$iterations=1;}

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
	    chomp $genename;
	    #print "$genename\n";
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
 
open(RF, ">$GoEvaluationCorrelationRanges")  || die ("Can't open $GoEvaluationCorrelationRanges for writing: $!\n");
if ($opt_c){open (COMMONTERMS, ">$commonterms") || die ("Can't open $commonterms for writing $!\n");}

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
   		if ($opt_r)
      		{ 
       		$gene1_arr[$x] =  $gene1;
       		$gene2_arr[$x] =  $gene2;
       		$corr_arr[$x] =  $r;
       		print "Array Load: gene1->$gene1;, gene2->$gene2, corr->$r\r" if DEBUG;
       		$x++;
       		}
    	else {
       		print "EXPR results loaded: $exprcount gene1->$1, gene2-> $2, corr->$3\r" if DEBUG;
       		$EXPR{gpair($gene1,$gene2)} = $r;
      		}

  	}
}
close(EXPRRESULTS);
 
for (my $v = 0; $v < $iterations; $v++) { 
    

	if ($opt_r) {
   		for  (my $j = 0; $j < $exprcount; $j++) {
       	my $r = $corr_arr[rand @corr_arr];  # randomly pick an element from array
       	print "Rand Array->Hash: gene1->$gene1_arr[$j], gene2->$gene2_arr[$j], correlation->$r \r" if DEBUG;
       	
       	$EXPR{gpair($gene1_arr[$j],$gene2_arr[$j])} = $r;
   		} #end for
	}  
 	print "Iteration Step->$v\n";
 	print "Iteration Step->$v\n" if DEBUG;
#     
#-------------------------------------------------------------------------------------------     
# 
	my @GOTermCount = ();
	my @GOGenePairCount = ();
	my $i = 0; 
	for(my $k = $lower; $k <= $upper ; $k++)
    	{$GOTermCount[$k] = 0;}
	for(my $k = $lower; $k <= $upper ; $k++)
    	{ $GOGenePairCount[$k] = 0;}

	
 	foreach my $gene_key (sort {$a <=> $b} keys %EXPR){
 		my @gene = revgpair($gene_key);
		my $gene1 = $gene[0];  
        my $gene2 = $gene[1];
  		if ((defined($geneassochash{$gene1})) && (defined($geneassochash{$gene2})) ) {   
  			#my $correlation_value = ($EXPR{gpair($gene1,$gene2)})*(-1); 
  			my $correlation_value = $EXPR{gpair($gene1,$gene2)}; 
  			my $pvalue = 0;
  			my $neighbor = 0;
  			my $commontermid = 0;
			if ($correlation_value >= $minimum) { 
  				$i = ceil($correlation_value*10 + .000001); 
      			print "Processing Gene1: $gene1  Gene2 $gene2\r" if DEBUG;
        		$GOGenePairCount[$i]++;  
           		($neighbor, $commontermid) =  &Nodeneighbors($gene1, $gene2,\%geneassochash);
           			if ($neighbor == 1) {
              			$pvalue = &ProbabilityCalc($commontermid, \%GOTermcounthash);              				
				if ($opt_c){print COMMONTERMS "$gene1\t$gene2\t$correlation_value\t$commontermid\n";}
              			$GOTermCount[$i]++;  
            		} # end if
            } #end if corr positive
    	} # end if defined gene1 && gene2 
   	} # end for each
 		
 
	# Write out the GO evaluation ranksummary  
#	print RF join ("\t",@GOTermCount),"\t///\t";
#	print RF join ("\t",@GOGenePairCount),"\n";

	for(my $k = $lower; $k <= $upper; $k++){
	  if ($GOTermCount[$k]){
	    print RF  "$GOTermCount[$k]\t";
	  }else{
	    print RF "0\t"
	  }
	}
	print RF "/\t";
	for(my $k = $lower; $k <= $upper; $k++){
	  if ($GOGenePairCount[$k]){
	    print RF  "$GOGenePairCount[$k]\t";
	  }else{
	    print RF "0\t"
	  }
	}
	print RF "\n";

} # end for $v
close(RF);
if ($opt_c){close(COMMONTERMS);}
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
#-----------------------------------------------------------------------------------------
sub gpair ($$) { 
my $gene1 = shift; 
my $gene2 = shift; 
return join ('&', sort numerically($gene1, $gene2)); } 
#-----------------------------------------------------------------------------------------

sub revgpair($) {
my $genekey = shift;
#print "genekey->$genekey\n";
my @genes = split (/&/,$genekey);
#print "genearray->@genes\n";
return (@genes);
}
#-----------------------------------------------------------------------------------------
sub numerically {$a <=> $b;}

