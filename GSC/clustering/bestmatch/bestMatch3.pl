#!/usr/bin/perl -w

use strict;
use Data::Dumper;
use Getopt::Std;

getopts("a:b:n:o:");
use vars qw($opt_a $opt_b $opt_n $opt_o);

#load all genes and their best matches for platform1 and platform2 results into hashes
#compare results of two methods by seeing how often they agree.

unless($opt_a && $opt_b && $opt_n){&printDocs();}

my $platform1results = $opt_a;
my $platform2results = $opt_b;
my $outfile = $opt_o;
#my $platform1results = "sagetest.txt";
#my $platform2results = "microtest.txt";

my (%PLATFORM1, %PLATFORM2, %PLATFORM1_BEST, %PLATFORM2_BEST, %summary, %results, %best_results);
my $neighborhood = $opt_n;
my $platform1rank;
my $matchcount = 0;
my $platform1_gene_count = 0;
my $cumulative_percent =0;
my $cumulative_matches = 0;

if ($opt_o){open (OUTFILE, ">$outfile") or die "can't open $outfile\n";}

#load platform1 results
print "\nLoading platform1 results into hash\n";
open (PLATFORM1RESULTS, $platform1results) or die "can't open $platform1results\n";
my $platform1count = 0;
while (<PLATFORM1RESULTS>){
  if ($_=~/^(\S+)\s+(\S+)\s+(\S+)/){
    $platform1count++;
    print "Platform1 results loaded: $platform1count\r";
    my $gene1 = $1;
    my $gene2 = $2;
    my $r = $3;
    #if necessary to save on memory, there should be a way to store only one of these
    $PLATFORM1{$gene1}{$gene2}=$r;
    $PLATFORM1{$gene2}{$gene1}=$r;
  }
}

#Find best n matches for each gene in platform1 and create a new smaller hash
print "\nSorting and transferring Platform1 top $neighborhood matches to smaller hash\n";
my $platform1_bestcount = 0;
foreach my $gene1 (sort {$a <=> $b} keys %PLATFORM1){
  my $i = 1;
  foreach my $gene2 (sort {$PLATFORM1{$gene1}{$b} <=> $PLATFORM1{$gene1}{$a}} (keys(%{$PLATFORM1{$gene1}}))){
    if ($i <= $neighborhood){
      $PLATFORM1_BEST{$gene1}{$gene2}=$PLATFORM1{$gene1}{$gene2};
      $platform1_bestcount++;
      print "Platform1 best results loaded: $platform1_bestcount\r";
      $i++;
    }else{
      last;
    }
  }
}

#Flush out large platform1 hash - How do you do this?  If I use either method below, it seems to freeze the script.
#print "\nAttempting to free memory from large Platform1 hash\n";
#undef %PLATFORM1;
#%PLATFORM1=();

#load platform2 results
print "\n\nLoading platform2 results into hash\n";
open (PLATFORM2RESULTS, $platform2results) or die "can't open $platform2results\n";
my $platform2count = 0;
while (<PLATFORM2RESULTS>){
  if ($_=~/^(\S+)\s+(\S+)\s+(\S+)/){
    my $gene1 = $1;
    my $gene2 = $2;
    my $r = $3;
    #if this gene pair is in the platform1 dataset, add it to the platform2 set (this will save on memory)
    if ($PLATFORM1{$gene1}{$gene2}){
      $platform2count++;
      print "Platform2 results loaded: $platform2count\r";
      #if necessary to save on memory, there should be a way to store only one of these
      $PLATFORM2{$gene1}{$gene2}=$r;
      $PLATFORM2{$gene2}{$gene1}=$r;
    }
  }
}

#Find best n matches for each gene in platform1 and create a new smaller hash
print "\nSorting and transferring Platform2 top $neighborhood matches to smaller hash\n";
my $platform2_bestcount = 0;
foreach my $gene1 (sort {$a <=> $b} keys %PLATFORM2){
  my $i = 1;
  foreach my $gene2 (sort {$PLATFORM2{$gene1}{$b} <=> $PLATFORM2{$gene1}{$a}} (keys(%{$PLATFORM2{$gene1}}))){
    if ($i <= $neighborhood){
      $PLATFORM2_BEST{$gene1}{$gene2}=$PLATFORM2{$gene1}{$gene2};
      $platform2_bestcount++;
      print "Platform2 best results loaded: $platform2_bestcount\r";
      $i++;
    }else{
      last;
    }
  }
}

#Flush out large platform2 hash - How do you do this?
#print "\nAttempting to free memory from large Platform2 hash\n";
#undef %PLATFORM2;
#%PLATFORM2=();

print "\n\nfinding best matches\n";
#For each gene in the platform1 results, find the gene that is closest to it (ie. highest pearson correlation)
#What about strong negative correlations?
foreach my $gene1 (sort {$a <=> $b} keys %PLATFORM1_BEST){
  $platform1rank = 0;
  $platform1_gene_count++;
  my $i = 1;
  foreach my $gene2 (sort {$PLATFORM1_BEST{$gene1}{$b} <=> $PLATFORM1_BEST{$gene1}{$a}} (keys(%{$PLATFORM1_BEST{$gene1}}))){
    if ($i <= $neighborhood){
      $platform1rank = $i;
      #Now, see if each genes best match is the same in the platform2 data
      #To make this script run faster, you could create a new hash with just the top n best matches for each gene for both platforms
      #Then, dump the huge hash and only have to search the smaller ones.
      my $matchcheck = &checkNeighborhood($gene1,$gene2);
      $i++;
    }else{
      last;
    }
  }
}
print "\n\n----------------------Summary----------------------------\n\n";
print "$platform1_gene_count genes analysed\n";
print "Checked top $neighborhood platform1 matches against top $neighborhood platform2 matches\n";
print "Found $matchcount matches between platform1 and platform2\n\n";
if ($opt_o){
print OUTFILE "\n\n----------------------Summary----------------------------\n\n";
print OUTFILE "$platform1_gene_count genes analysed\n";
print OUTFILE "Checked top $neighborhood platform1 matches against top $neighborhood platform2 matches\n";
print OUTFILE "Found $matchcount total matches between platform1 and platform2\n\n";
}
#print "\n\nRank\tMatches\tPercent\tCumulative Percent\n";

#print Dumper (%summary);

foreach my $platform1rank (sort {$a<=>$b} keys %summary){
#  print "checking platform1rank: $platform1rank\n";
  my $sub_cumulative_matches = 0;
  my $sub_cumulative_percent = 0;
  foreach my $platform2rank (sort {$a<=>$b} keys %{$summary{$platform1rank}}){
#    print "checking $platform2rank\n";
    my $matches = $summary{$platform1rank}{$platform2rank};
    my $percent = ($matches/$platform1_gene_count)*100;
    $sub_cumulative_percent = $sub_cumulative_percent + $percent;
    $cumulative_percent = $cumulative_percent + $percent;
    $sub_cumulative_matches = $sub_cumulative_matches + $matches;
    $cumulative_matches = $cumulative_matches + $matches;
#    print "$platform1rank\t$platform2rank\t$matches\t$percent\t$cumulative_percent\n";
  }
#  print "\n$platform1rank\t$sub_cumulative_matches\t$sub_cumulative_percent\t$cumulative_percent\n";
}

#
#It would be good to summarize how many genes within the top 1 for both platform1 and platform2 matched, top 2, etc...
#Another problem with the method above is that it starts with platform1 best match and goes through top 10 platform2, 
#then considers 2nd best platform1 and goes thru top 10 platform2.  Thus, the 2nd best match for platform1 and 8th best match
#for platform2 will be reported even if the 3rd best platform1 vs 2nd best platform2 would arguably be better

#Go through results hash and find best combination of ranks for platform1 and platform2 for each gene
foreach my $gene (sort {$a<=>$b} keys %results){
#the worst rank they can have is the max neighborhood allowed for each.  Otherwise, they shouldn't be in the %results hash
  my $best_platform1_rank = $neighborhood;
  my $best_platform2_rank = $neighborhood;
  my $best_cum_rank = $best_platform1_rank + $best_platform2_rank;
  foreach my $platform1rank (sort {$a<=>$b} keys %{$results{$gene}}){
    foreach my $platform2rank (sort {$a<=>$b} keys %{$results{$gene}{$platform1rank}}){
      my $cum_rank = $platform1rank + $platform2rank;
      if ($cum_rank < $best_cum_rank){
	$best_cum_rank = $cum_rank;
	$best_platform1_rank = $platform1rank;
	$best_platform2_rank = $platform2rank;
      }
    }
  }
  $best_results{$gene}{$best_platform1_rank}{$best_platform2_rank}++;
}
#print Dumper (%best_results);

#Now, print out number of genes with top n matches for both platforms
print "Numbers of genes with overall best match in neighborhood of size $neighborhood\n";
print "neighborhood\tcumulative_matches\tcumulative_percent\n";
if ($opt_o){
  print OUTFILE "Numbers of genes with overall best match in neighborhood of size $neighborhood\n";
  print OUTFILE "\n\nneighborhood\tcumulative_matches\tcumulative_percent\n";
}
my $i;
my $cum_matches = 0;
for ($i=1; $i<=$neighborhood; $i++){
  my $matches = 0;
  foreach my $gene (sort {$a<=>$b} keys %best_results){
    foreach my $platform1rank (sort {$a<=>$b} keys %{$best_results{$gene}}){
      foreach my $platform2rank (sort {$a<=>$b} keys %{$best_results{$gene}{$platform1rank}}){
#	print "comparing platform2rank: $platform2rank and platform1rank: $platform1rank to $i\n";
	if ($platform1rank <= $i && $platform2rank <= $i){
#	  print "The number $platform1rank best match for platform1 matches the number $platform2rank best match for platform2!\n";
	  $matches++;
	}
      }
    }
  }
  my $percent = ($matches/$platform1_gene_count)*100;
  print "$i\t$matches\t$percent\n";
  if ($opt_o){print OUTFILE "$i\t$matches\t$percent\n";}
}
print "\n\n---------------------------End Summary----------------------------------\n";
if ($opt_o){
  print OUTFILE "\n\n---------------------------End Summary----------------------------------\n";
  close OUTFILE;
}



exit;
sub checkNeighborhood{
#See if the best n match for platform1 is within the top n matches for the platform2 data where n is set by $neighborhood
  my $platform1_gene1 = shift @_;
  my $platform1_gene2 = shift @_;
  my $matchcheck = 0;
  my $i = 0;
  my $platform2rank = 0;
  my ($platform1_value , $platform2_value);
  foreach my $platform2_gene2 (sort {$PLATFORM2_BEST{$platform1_gene1}{$b} <=> $PLATFORM2_BEST{$platform1_gene1}{$a}} (keys(%{$PLATFORM2_BEST{$platform1_gene1}}))){
    $i++;
    if ($i <= $neighborhood){
      $platform1_value=$PLATFORM1_BEST{$platform1_gene1}{$platform1_gene2};
      $platform2_value=$PLATFORM2_BEST{$platform1_gene1}{$platform2_gene2};
      #Do they match?
      if ($platform1_gene2 == $platform2_gene2){
	$platform2rank = $i;
	print "\nplatform1: $platform1_gene1\t$platform1_gene2\t$platform1_value\n";
	print "Platform2: $platform1_gene1\t$platform2_gene2\t$platform2_value\n";
	print "The number $platform1rank best match for platform1 matches the number $platform2rank best match for platform2!\n";
	if ($opt_o){print OUTFILE "$platform1_gene1\t$platform1_gene2:\tplatform1 $platform1_value($platform1rank) matches platform2 $platform2_value($platform2rank)\n";}
	$summary{$platform1rank}{$platform2rank}++;
	$results{$platform1_gene1}{$platform1rank}{$platform2rank}++;
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

sub printDocs{
  print "This script takes two tab-delimited files of the form 'gene1  gene2  value' and compares the best values between files (eg. platforms)\n";
  print "A shared best match is anything within a specified neighborhood size of n\n";
  print "The following options are required:\n";
  print "-a file1\n";
  print "-b file2\n";
  print "-n neighborhood size\n";
  print "-o outputfile\n";
  print "Usage: bestMatch2.pl -a sagetest.txt -b microtest.txt -n 3\n";
  exit;
}
