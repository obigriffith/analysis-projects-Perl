#!/usr/bin/perl -w

use strict;
use Data::Dumper;
use Getopt::Std;
use Storable;

$|=1;

getopts("a:b:n:o:r");
use vars qw($opt_a $opt_b $opt_n $opt_o $opt_r);
#load all genes and their best matches for platform1 and platform2 results into hashes
#compare results of two methods by seeing how often they agree.
srand(time|$$);

unless($opt_a && $opt_b && $opt_n){&printDocs();}

my $platform1results = $opt_a;
my $platform2results = $opt_b;
my $outfile = $opt_o;
my $bestgenepairlist;
#my $bestgenepairlist = "$outfile".".genelist";
#my $platform1results = "sagetest.txt";
#my $platform2results = "microtest.txt";

my (%PLATFORM1, %PLATFORM2, %PLATFORM1_BEST, %PLATFORM2_BEST, %results, %best_results, %bestgenepairlist);
my $neighborhood = $opt_n;
my $platform1rank;
my $matchcount = 0;
my $platform1_gene_count = 0;
my $cumulative_percent =0;
my $cumulative_matches = 0;
my $platform1count = 0;
my $platform2count = 0;

if ($opt_o){
  open (OUTFILE, ">$outfile") or die "can't open $outfile\n";
  open (BESTGENEPAIRLIST, ">$bestgenepairlist") or die "can't open $bestgenepairlist\n";
}

#load platform1 results
##print "\nLoading platform1 results\n";
#Retrieve pre-loaded data from file using Storable's retrieve function.
#Expects an array with three references to @x1, @y1, and @r1 arrays
my @arrays1 = @{retrieve($platform1results)};
my ($x1_ref,$y1_ref,$r1_ref) = @arrays1[0 .. 2];
my @x1 = @$x1_ref;  my @y1 = @$y1_ref;  my @r1 = @$r1_ref; #dereference arrays

# randomize @r1 only.  If we randomize either @x1 or @y1 we end up with weird gene pairs (2 vs 2, or multiple pairs that are the same)
if ($opt_r){
##  print "\nrandomizing data in arrays\n";
  @r1 = sort { rand() <=> rand() } @r1;
}
while (@x1) {
  # pick a random $y,$r
  my $gene1 = shift @x1;
  my $gene2 = shift @y1;
  my $r = shift @r1;
  $PLATFORM1{$gene1}{$gene2} = $r;
  $PLATFORM1{$gene2}{$gene1} = $r;
  $platform1count++;
##  print "Results transferred from arrays to hash: $platform1count\r";
}

#Find best n matches for each gene in platform1 and create a new smaller hash
##print "\nSorting and transferring Platform1 top $neighborhood matches to smaller hash\n";
my $platform1_bestcount = 0;
foreach my $gene1 (sort {$a <=> $b} keys %PLATFORM1){
  my $i = 1;
  foreach my $gene2 (sort {$PLATFORM1{$gene1}{$b} <=> $PLATFORM1{$gene1}{$a}} (keys(%{$PLATFORM1{$gene1}}))){
    if ($i <= $neighborhood){
      $PLATFORM1_BEST{$gene1}{$gene2}=$PLATFORM1{$gene1}{$gene2};
      $platform1_bestcount++;
##      print "Platform1 best results loaded: $platform1_bestcount\r";
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
##print "\n\nLoading platform2 results\n";
#Retrieve pre-loaded data from file using Storable's retrieve function.
#Expects an array with three references to @x2, @y2, and @r2 arrays
my @arrays2 = @{retrieve($platform2results)};
my ($x2_ref,$y2_ref,$r2_ref) = @arrays2[0 .. 2];
my @x2 = @$x2_ref;  my @y2 = @$y2_ref;  my @r2 = @$r2_ref; #dereference arrays

# randomize @r2 only.  If we randomize either @x2 or @y2 we end up with weird gene pairs (2 vs 2, or multiple pairs that are the same)
if ($opt_r){
##  print "\nrandomizing data in arrays\n";
  @r2 = sort { rand() <=> rand() } @r2;
}

while (@x2) {
  # pick a random $y,$r
  my $gene1 = shift @x2;
  my $gene2 = shift @y2;
  my $r = shift @r2;
  $PLATFORM2{$gene1}{$gene2} = $r;
  $PLATFORM2{$gene2}{$gene1} = $r;
  $platform2count++;
##  print "Results transferred from arrays to hash: $platform2count\r";
}

#Find best n matches for each gene in platform1 and create a new smaller hash
##print "\nSorting and transferring Platform2 top $neighborhood matches to smaller hash\n";
my $platform2_bestcount = 0;
foreach my $gene1 (sort {$a <=> $b} keys %PLATFORM2){
  my $i = 1;
  foreach my $gene2 (sort {$PLATFORM2{$gene1}{$b} <=> $PLATFORM2{$gene1}{$a}} (keys(%{$PLATFORM2{$gene1}}))){
    if ($i <= $neighborhood){
      $PLATFORM2_BEST{$gene1}{$gene2}=$PLATFORM2{$gene1}{$gene2};
      $platform2_bestcount++;
##      print "Platform2 best results loaded: $platform2_bestcount\r";
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

##print "\n\nfinding best matches\n";
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
##print "\n\n----------------------Summary----------------------------\n\n";
##print "$platform1_gene_count genes analysed\n";
##print "Checked top $neighborhood platform1 matches against top $neighborhood platform2 matches\n";
##print "Found $matchcount matches between platform1 and platform2\n\n";
if ($opt_o){
##print OUTFILE "\n\n----------------------Summary----------------------------\n\n";
##print OUTFILE "$platform1_gene_count genes analysed\n";
##print OUTFILE "Checked top $neighborhood platform1 matches against top $neighborhood platform2 matches\n";
##print OUTFILE "Found $matchcount total matches between platform1 and platform2\n\n";
}

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
  my $gene2 = $results{$gene}{$best_platform1_rank}{$best_platform2_rank};
  $best_results{$gene}{$best_platform1_rank}{$best_platform2_rank}=$gene2;
}
#print Dumper (%best_results);

#Now, print out number of genes with top n matches for both platforms
##print "Numbers of genes with overall best match in neighborhood of size $neighborhood\n";
##print "neighborhood\tcumulative_matches\tcumulative_percent\n";
if ($opt_o){
##  print OUTFILE "Numbers of genes with overall best match in neighborhood of size $neighborhood\n";
##  print OUTFILE "\n\nneighborhood\tcumulative_matches\tcumulative_percent\n";
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
	  my $gene2 = $best_results{$gene}{$platform1rank}{$platform2rank};
	  unless ($bestgenepairlist{$gene}{$gene2}){  #Unless the gene pair has already been counted in a smaller neighborhood, add it to the hash for its current neighborhood size
	    $bestgenepairlist{$gene}{$gene2}=$i;
	  }
	  $matches++;
	}
      }
    }
  }
  my $percent = ($matches/$platform1_gene_count)*100;
  print "$i\t$matches\t$percent\n";
##  if ($opt_o){print OUTFILE "$i\t$matches\t$percent\n";}
}

#print the actual list of genepairs with shared bestmatches for each neighborhood size to a separate file
##print "\n\nNeighborhood\tgene1\tgene2\tplatform1_r\tplatform2_r\n";
if ($opt_o){print "\n\nNeighborhood\tgene1\tgene2\tplatform1_r\tplatform2_r\n";}
foreach my $gene1 (sort {$a<=>$b} keys %bestgenepairlist){
  foreach my $gene2 (sort {$a<=>$b} keys %{$bestgenepairlist{$gene1}}){
    my $neighbourhood = $bestgenepairlist{$gene1}{$gene2};
    my $platform1_value = $PLATFORM1_BEST{$gene1}{$gene2};
    my $platform2_value = $PLATFORM2_BEST{$gene1}{$gene2};
##    print "$neighbourhood\t$gene1\t$gene2\t$platform1_value\t$platform2_value\n";
    if ($opt_o){print BESTGENEPAIRLIST "$neighbourhood\t$gene1\t$gene2\t$platform1_value\t$platform2_value\n";}
  }
}

##print "\n\n---------------------------End Summary----------------------------------\n";
if ($opt_o){
##  print OUTFILE "\n\n---------------------------End Summary----------------------------------\n";
  close OUTFILE;
  close BESTGENEPAIRLIST;
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
##	print "\nplatform1: $platform1_gene1\t$platform1_gene2\t$platform1_value\n";
##	print "Platform2: $platform1_gene1\t$platform2_gene2\t$platform2_value\n";
##	print "The number $platform1rank best match for platform1 matches the number $platform2rank best match for platform2!\n";
	if ($opt_o){print OUTFILE "$platform1_gene1\t$platform1_gene2:\tplatform1 $platform1_value($platform1rank) matches platform2 $platform2_value($platform2rank)\n";}
	$results{$platform1_gene1}{$platform1rank}{$platform2rank}=$platform1_gene2;
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
  print "-r randomize data\n";
  print "-o outputfile\n";
  print "Usage: bestMatch2.pl -a sagetest.txt -b microtest.txt -n 3\n";
  exit;
}
