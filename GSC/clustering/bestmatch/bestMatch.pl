#!/usr/bin/perl -w

use strict;
use Data::Dumper;

#load all genes and their best matches for sage and microarray results into hashes
#compare results of two methods by seeing how often they agree.

my $sageresults = "/home/obig/clustering/SAGE/sageresults/final_SAGE_results_dror_cut05.txt";
my $microresults = "/home/obig/clustering/microarray/microarray_results/human/human_microarray_common2sage_w_nulls.txt";
#my $sageresults = "sagetest.txt";
#my $microresults = "microtest.txt";


my %SAGE;
my %micro;
my %summary;
my %results;
my %best_results;
my $microneighborhood = 10;
my $sageneighborhood = 10;
my $neighborhood = 10;
my $sagerank;
my $matchcount = 0;
my $sage_gene_count = 0;
my $cumulative_percent =0;
my $cumulative_matches = 0;

#load sage results
print "\nLoading SAGE results into hash\n";
open (SAGERESULTS, $sageresults) or die "can't open $sageresults\n";
my $sagecount = 0;
while (<SAGERESULTS>){
  if ($_=~/^(\S+)\s+(\S+)\s+(\S+)/){
    $sagecount++;
    print "SAGE results loaded: $sagecount\r";
    my $gene1 = $1;
    my $gene2 = $2;
    my $r = $3;
    #if necessary to save on memory, there should be a way to store only one of these
    $SAGE{$gene1}{$gene2}=$r;
    $SAGE{$gene2}{$gene1}=$r;
  }
}

#load microarray results
print "\n\nLoading microarray results into hash\n";
open (MICRORESULTS, $microresults) or die "can't open $microresults\n";
my $microcount = 0;
while (<MICRORESULTS>){
  if ($_=~/^(\S+)\s+(\S+)\s+(\S+)/){
    my $gene1 = $1;
    my $gene2 = $2;
    my $r = $3;
    #if this gene pair is in the SAGE dataset, add it to the microarray set (this will save on memory)
    if ($SAGE{$gene1}{$gene2}){
      $microcount++;
      print "Microarray results loaded: $microcount\r";
      #if necessary to save on memory, there should be a way to store only one of these
      $micro{$gene1}{$gene2}=$r;
      $micro{$gene2}{$gene1}=$r;
    }
  }
}

print "\n\nfinding best matches\n";
#For each gene in the sage results, find the gene that is closest to it (ie. highest pearson correlation)
#What about strong negative correlations?
foreach my $gene1 (sort {$a <=> $b} keys %SAGE){
  $sagerank = 0;
  $sage_gene_count++;
  my $i = 1;
  foreach my $gene2 (sort {$SAGE{$gene1}{$b} <=> $SAGE{$gene1}{$a}} (keys(%{$SAGE{$gene1}}))){
    if ($i <= $sageneighborhood){
      $sagerank = $i;
      #Now, see if each genes best match is the same in the microarray data
      my $matchcheck = &checkNeighborhood($gene1,$gene2);
      #If you find a match for the nth best sage match within the nth best micro matches, move on to the next gene
      #Ultimately, we want to consider all matches within the neighborhood, but the summary has to be changed
      #if ($matchcheck == 1){last;}
      $i++;
    }else{
      last;
    }
  }
}
print "\n\n----------------------Summary----------------------------\n";
print "\n$sage_gene_count genes analysed\n";
print "Checked top $sageneighborhood SAGE matches against top $microneighborhood microarray matches\n";
print "\nFound $matchcount matches between SAGE and microarray\n";
#print "\n\nRank\tMatches\tPercent\tCumulative Percent\n";

#print Dumper (%summary);

foreach my $sagerank (sort {$a<=>$b} keys %summary){
#  print "checking sagerank: $sagerank\n";
  my $sub_cumulative_matches = 0;
  my $sub_cumulative_percent = 0;
  foreach my $microrank (sort {$a<=>$b} keys %{$summary{$sagerank}}){
#    print "checking $microrank\n";
    my $matches = $summary{$sagerank}{$microrank};
    my $percent = ($matches/$sage_gene_count)*100;
    $sub_cumulative_percent = $sub_cumulative_percent + $percent;
    $cumulative_percent = $cumulative_percent + $percent;
    $sub_cumulative_matches = $sub_cumulative_matches + $matches;
    $cumulative_matches = $cumulative_matches + $matches;
#    print "$sagerank\t$microrank\t$matches\t$percent\t$cumulative_percent\n";
  }
#  print "\n$sagerank\t$sub_cumulative_matches\t$sub_cumulative_percent\t$cumulative_percent\n";
}

#
#It would be good to summarize how many genes within the top 1 for both sage and microarray matched, top 2, etc...
#Another problem with the method above is that it starts with SAGE best match and goes through top 10 micro, 
#then considers 2nd best SAGE and goes thru top 10 microarray.  Thus, the 2nd best match for SAGE and 8th best match
#for microarray will be reported even if the 3rd best SAGE vs 2nd best microarray would arguably be better

#Go through results hash and find best combination of ranks for sage and microarray for each gene
foreach my $gene (sort {$a<=>$b} keys %results){
#the worst rank they can have is the max neighborhood allowed for each.  Otherwise, they shouldn't be in the %results hash
  my $best_sage_rank = $sageneighborhood;
  my $best_micro_rank = $microneighborhood;
  my $best_cum_rank = $best_sage_rank + $best_micro_rank;
  foreach my $sagerank (sort {$a<=>$b} keys %{$results{$gene}}){
    foreach my $microrank (sort {$a<=>$b} keys %{$results{$gene}{$sagerank}}){
      my $cum_rank = $sagerank + $microrank;
      if ($cum_rank < $best_cum_rank){
	$best_cum_rank = $cum_rank;
	$best_sage_rank = $sagerank;
	$best_micro_rank = $microrank;
      }
    }
  }
  $best_results{$gene}{$best_sage_rank}{$best_micro_rank}++;
}
#print Dumper (%best_results);

#Now, print out number of genes with top n matches for both platforms
print "\nNumbers of genes with overall best match in neighborhood of size n\n";
print "neighborhood\tmatches\n";
my $i;
for ($i=1; $i<=$neighborhood; $i++){
  my $matches = 0;
  foreach my $gene (sort {$a<=>$b} keys %best_results){
    foreach my $sagerank (sort {$a<=>$b} keys %{$best_results{$gene}}){
      foreach my $microrank (sort {$a<=>$b} keys %{$best_results{$gene}{$sagerank}}){
#	print "comparing microrank: $microrank and sagerank: $sagerank to $i\n";
	if ($sagerank <= $i && $microrank <= $i){
#	  print "The number $sagerank best match for SAGE matches the number $microrank best match for microarray!\n";
	  $matches++;
	}
      }
    }
  }
  print "$i\t$matches\n";
}
print "\n\n---------------------------End Summary----------------------------------\n";

sub checkNeighborhood{
#See if the best n match for SAGE is within the top n matches for the microarray data where n is set by $neighborhood
  my $sage_gene1 = shift @_;
  my $sage_gene2 = shift @_;
  my $matchcheck = 0;
  my $i = 0;
  my $microrank = 0;
  my $micro_gene2_value;
  foreach my $micro_gene2 (sort {$micro{$sage_gene1}{$b} <=> $micro{$sage_gene1}{$a}} (keys(%{$micro{$sage_gene1}}))){
    $i++;
    if ($i <= $microneighborhood){
      $micro_gene2_value=$micro{$sage_gene1}{$micro_gene2};
      #Do they match?
      if ($sage_gene2 == $micro_gene2){
	$microrank = $i;
	print "\nSAGE: $sage_gene1\t$sage_gene2\t$SAGE{$sage_gene1}{$sage_gene2}\n";
	print "Microarray: $sage_gene1\t$micro_gene2\t$micro_gene2_value\n";
	print "The number $sagerank best match for SAGE matches the number $microrank best match for microarray!\n";
	$summary{$sagerank}{$microrank}++;
	$results{$sage_gene1}{$sagerank}{$microrank}++;
	$matchcheck = 1;
	$matchcount++;
	last;
      }
    }else{
      last;
    }
  }
return ($matchcheck);
}
