 
#!/usr/bin/perl
 
=head1 NAME

  	BestMatchOverall.pl

=head1 SYNOPSIS
	
	BestMatchOverall.pl
	
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

use constant VERSION 	=> "BestMatchOverall 1.0";
use constant DEBUG 		=> 0;
use constant USAGE 		=> "BestMatchOverall.pl";
 
 
 
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

my %EXPR;
$exprneighborhood = 10;

#load expr results
print "\nLoading Correlation results into hash\n";
my $exprcount = 0;

# ====================== Load AFFY Data ===============================================
my $exprresults = "/home/egarland/Projects/SAGE/clustering/matrix/affy_micro_sage_comp/" . 
                   "results/final_AFFY_results_humanGEO_U133A_common2all.txt";
#my $exprresults = "datatest2.txt";
open (EXPRRESULTS, $exprresults) or die "can't open $exprresults\n";
while (<EXPRRESULTS>){
	if ($_=~/^(\S+)\s+(\S+)\s+(\S+)/){     
    	$exprcount++;
       	my $gene1 = $1;
       	my $gene2 = $2;
       	my $r = $3; 
                        
  
       	print "EXPR results loaded AFFY->$exprcount EXPR gene1->$gene1, gene2->$gene2, corr->$r\r" if DEBUG;
       
      
       ; 
       # hash table value is an array of summed correlation with the second element representing
       # the number of platforms contributing to the sum
       $EXPR{gpair($gene1,$gene2)} = [$r, 1];
  } # end if
}# end while
close(EXPRRESULTS);
print "\n\n" if DEBUG;
# ====================== Load SAGE Data ===============================================
my $exprresults = "/home/egarland/Projects/SAGE/clustering/matrix/affy_micro_sage_comp/" . 
                   "results/final_SAGE_nofilter_log_freqs_results_common2all.txt";
#my $exprresults = "datatest2.txt";
open (EXPRRESULTS, $exprresults) or die "can't open $exprresults\n";
while (<EXPRRESULTS>){
  	if ($_=~/^(\S+)\s+(\S+)\s+(\S+)/){     
  		$exprcount++;
       	my $gene1 = $1;
       	my $gene2 = $2;
       	my $r = $3; 
                        
  
       	print "EXPR results loaded SAGE->$exprcount EXPR gene1->$gene1, gene2->$gene2, corr->$r\r" if DEBUG;
           
     	if  (defined($EXPR{gpair($gene1,$gene2)}) ) {# check to see if gene pair defined
         	$EXPR{gpair($gene1,$gene2)}[0] = $EXPR{gpair($gene1,$gene2)}[0] + $r;
         	$EXPR{gpair($gene1,$gene2)}[1]++;     # increment the number of platforms where gene pair found
         	
          	
      	} # end if
   
      	else
           {  $EXPR{gpair($gene1,$gene2)}  = [$r, 1];
            
           }
      
  	} # end if
}# end while
close(EXPRRESULTS);   
print "\n\n" if DEBUG;
# ====================== Load cDNA Data ===============================================
my $exprresults = "/home/egarland/Projects/SAGE/clustering/matrix/affy_micro_sage_comp/" . 
                   "results/final_micro_results_common2all.txt";  
#
#my $exprresults = "datatest2.txt";
open (EXPRRESULTS, $exprresults) or die "can't open $exprresults\n";
while (<EXPRRESULTS>){
	if ($_=~/^(\S+)\s+(\S+)\s+(\S+)/){     
     	$exprcount++;
       	my $gene1 = $1;
       	my $gene2 = $2;
       	my $r = $3; 
                        
  
       	print "EXPR results loaded cDNA->$exprcount EXPR gene1->$gene1, gene2->$gene2, corr->$r\r" if DEBUG;
           
     	if  (defined($EXPR{gpair($gene1,$gene2)}) ) {# check to see if gene pair defined
     	    $EXPR{gpair($gene1,$gene2)}[0] = $EXPR{gpair($gene1,$gene2)}[0] + $r;
     	    $EXPR{gpair($gene1,$gene2)}[1]++;     # increment the number of platforms where gene pair found
     
     
      	} # end if
   
      	else
      	{  $EXPR{gpair($gene1,$gene2)}  = [$r, 1];
            #print "NEW entry added for: Gene1: $gene1, Gene2:$gene2, Summed Corr: $r\n";
       	}
      
  	} # end if	
}# end while
close(EXPRRESULTS);   
print "\n\n" if DEBUG;


 
    
#------------------------------------------------------------------------------------------------------------------------
# Print the best overall match correlations
my $output = "AFFY_GEO_vs_SAGE_logfreqs_vs_micro_bestmatches_n10.2.txt.genelist_sorted";
print "\n\nSorting the correlation data\n" if DEBUG;

open(NF, ">$output")  || 
	die ("Can't open $output to write to: $!\n");

 
 foreach my $genepair (sort {$EXPR{$b}[0] <=> $EXPR{$a}[0]} keys %EXPR){
  
 	my @gene = revgpair($genepair);
 	my $gene1 = $gene[0];  
 	my $gene2 = $gene[1];
        
   	if  ($EXPR{gpair($gene1,$gene2)}[1] == 3) {   # Select only those gene pairs in common for all 3 platforms 
   		print "Genes In Common gene1->$gene1, Gene2->$gene2, Summed Corr-> $EXPR{gpair($gene1,$gene2)}[0]\r" if DEBUG;         
         
     	#printing gene1, gene2, summed corr, #platforms with gene pair, Affy Corr, Sage Corr, cDNA Corr 
      	print(NF join("\t",$gene1, $gene2, $EXPR{gpair($gene1,$gene2)}[0] ,$EXPR{gpair($gene1,$gene2)}[1],"\n"));
            
  	} #end if        
} # end foreach genepair

close(NF);

     	   	 
exit 0;
#____________________________________________________________________________________________________________________
# Sort the genes for the hash key
sub gpair ($$) { 
my $gene1 = shift; 
my $gene2 = shift; 
return join ('&', sort numerically($gene1, $gene2)); } 
#--------------------------------------------------------------------------------------------------------------------
# Extract the genes from the hash key
sub revgpair($) {
my $genekey = shift;
#print "genekey->$genekey\n";
my @genes = split (/&/,$genekey);
#print "genearray->@genes\n";
return (@genes);
}
#--------------------------------------------------------------------------------------------------
# Generic numerical sort
sub numerically {$a <=> $b;}

