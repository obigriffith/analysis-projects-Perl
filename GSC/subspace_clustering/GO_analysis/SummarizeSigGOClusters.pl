#!/usr/bin/perl -w

use strict;

use Data::Dumper;
use Getopt::Std;

getopts("d:t:");
use vars qw($opt_d $opt_t);

my $parent_dir = $opt_d;
my $threshold=$opt_t;

my @result_dirs = `ls $parent_dir`;

#print Dumper(@result_dirs);

foreach my $result_dir (@result_dirs){
  chomp $result_dir;
  my $clustername;
  if ($result_dir=~/(cluster\d+)\.txt\.dir/){
    $clustername=$1;
    my $result_file="$parent_dir"."$result_dir/"."$clustername".".txt.change";
    #print "$result_file\n";
    open (RESULTS, $result_file) or die "can't open $result_file\n";
    my $best_fdr=1;
    my $best_fdr_goterm;
    while (<RESULTS>){
      if ($_=~/(GO:\d+)_(\S+)\t(\d+)\t(\d+)\t(\S+)\t(\S+)\t(\S+)\t(\S+)\t(\S+)\t(\S+)\t(\S+)/){
	my $go_id=$1;
	my $go_descn=$2;
	my $fdr=$11;
	if ($fdr<$best_fdr){
	  $best_fdr=$fdr;
	  $best_fdr_goterm=$go_descn;
	}
      }
    }
    close RESULTS;
    if ($best_fdr<=$threshold){
      print "$clustername\t$best_fdr\t$best_fdr_goterm\n";
    }
  }
}

