#!/usr/bin/perl

=head1 NAME

  	GOanalysisNeighborhood.pl

=head1 SYNOPSIS
	
	GOanalysisNeighborhood.pl
	
=head1 ARGUMENTS

	
	N/A
  		
=head1 DESCRIPTION

	Enumerates the cardinalities of gene pair neighborhoods within an expression neighborhood 
	distance. This process uses the gene pair evaluation file produced from the GOanalysis 
	process.

=head1 AUTHOR

  	D.L.Fulton
  	Simon Fraser University
  	E-mail: dlfulton@sfu.ca

=cut
 


use POSIX;
use strict; 
use constant VERSION 	=> "GOanalysisNeighborhood 1.0";
use constant DEBUG 		=> 0;
use constant USAGE 		=> "GOanalysisNeighborhood.pl";
  
 
 my @gene1_arr = ();
 my @gene2_arr = ();
 my @InGO_arr = ();
 my @val_arr = ();
 my $exprneighborhood = 50;
 

#---- DATASETS ------------------------------------------------------------------------
#my $exprresults = "/home/egarland/Projects/SAGE/clustering/matrix/affy_micro_sage_comp/" . 
                   "results/final_micro_results_common2all.txt";  
#my $exprresults = "/home/egarland/Projects/SAGE/clustering/matrix/affy_micro_sage_comp/" . 
                   "results/final_AFFY_results_humanGEO_U133A_common2all.txt";
#my $exprresults = "/home/egarland/Projects/SAGE/clustering/matrix/affy_micro_sage_comp/" . 
                   "results/final_SAGE_nofilter_log_freqs_results_common2all.txt";
#--------------------------------------------------------------------------------------


my %EXPR;
$exprneighborhood = 10;

open(TARGET, "GoEvaluationGenePair") ||   
	die ("Can't open GoEvaluationGenePair: $!\n");

my $exprcount = 0;
my $x = 0;
while (<TARGET>){
 
	my $genepair_line = $_;
  	my @line_fields = split(/\t/,$genepair_line);
  	my $IN_GO = $line_fields[3];
  	my $gene1 = $line_fields[0];
  	my $gene2 = $line_fields[1];
  	my $r = $line_fields[2];    
    $val_arr[0] = $r;
    $val_arr[1] = $IN_GO;
  
  	print "Loading Hash gene1->$gene1, gene2->$gene2,\tarray value->@val_arr\n" if DEBUG; 
  	$exprcount++;  
   
  	$EXPR{$gene1}{$gene2} = $EXPR{$gene2}{$gene1} =  [$r,$IN_GO];

} # end while
close(TARGET);
 
#-----------------------------------------------------------------
# Step across correlation-sorted rows and count the number of GO annotations 
# in that neighborhood.

my @ranksummary = (); 
for(my $k = 1; $k <= $exprneighborhood ; $k++)
    {$ranksummary[$k] = 0;}
 
foreach my $gene1 (sort {$a <=> $b} keys %EXPR){
 	my $i = 0;
  	my $Neighborhood_Count = 0;  
    foreach my $gene2 (sort {$EXPR{$gene1}{$b}[0] <=> $EXPR{$gene1}{$a}[0]} #sort columns
						(keys(%{$EXPR{$gene1}}))){
    	print "Sorted Hash gene1->$gene1, gene2->$gene2,\tarray value->$EXPR{$gene1}{$gene2}[0],$EXPR{$gene1}{$gene2}[1]\r" if DEBUG; 
        $i++;
        if ($i <= $exprneighborhood)
        {
          	if ($EXPR{$gene1}{$gene2}[1] =~ /1/) {
              	$Neighborhood_Count++;
            }
        } # end if
        else {
         	$ranksummary[$Neighborhood_Count]++; 
           	last;
        
        } 
    } # end foreach gene2
} # end foreach gene1

close(NF);

open(NF, ">GoEvaluationNeighborhood")  || 
	die ("Can't open GoEvaluationNeighborhood for writing: $!\n");
for(my $k = 1; $k <= $exprneighborhood ; $k++)
  	{print NF  "$ranksummary[$k] ";}   # put this in a column to cut/paste to excel
close(NF);
     	   	 
exit 0;




