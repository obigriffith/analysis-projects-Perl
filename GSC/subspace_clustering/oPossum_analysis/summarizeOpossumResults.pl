#!/usr/local/bin/perl56 -w
#!/usr/bin/perl -w

use strict;
use Data::Dumper;
use Getopt::Std;

getopts("d:o:");
use vars qw($opt_o $opt_d);

my $result_dir = $opt_d;

my @result_files = `ls $result_dir`;
my %summary_stats;

#my @breaks = (-10,-9,-8,-7,-6,-5,-4,-3,-2,-1,0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,30,40,50,60,70);
my @breaks = (0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,30,40,50,60,70);

my $result_count=0;

foreach my $result_file (@result_files){
  unless ($result_file=~/\d+\.ztest/){next;} #only process files of expected format
  $result_count++;
  my $result_path="$result_dir/$result_file";
  open (RESULT, $result_path) or die "can't open $result_file\n";
  my $firstline=<RESULT>;
  my @scores;
  while (<RESULT>){
    chomp $_;
    my @entry=split("\t",$_);
    my $score=$entry[4];
    my $score_int=int($score);
    #print "$score_int\n";
    push(@scores, $score);
  }
  close RESULT;
  foreach my $break (@breaks){ #For each score break check see if there was one or more score greater
    foreach my $score (@scores){
      if ($score>=$break){
	$summary_stats{$break}++;
	last;#once one score has passed this threshold, skip to the next threshold
      }
    }
  }
}

#print Dumper (%summary_stats);
foreach my $score_category(sort{$a<=>$b} keys %summary_stats){
  my $score_category_count = $summary_stats{$score_category};
  my $score_category_freq = $score_category_count/$result_count;
  print "$score_category\t$score_category_count\t$score_category_freq\n";
}
