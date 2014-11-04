#!/usr/local/bin/perl56 -w
#!/usr/bin/perl -w

use strict;
use Data::Dumper;
use Getopt::Std;

getopts("f:d:r:i:");
use vars qw($opt_d $opt_o $opt_r $opt_i);

#This script takes a directory of cluster files (newline separated ENSG IDs) and creates a jobfile for the cluster

my $cluster_dir=$opt_d;
my $jobfile=$opt_o;
my $result_dir=$opt_r;
my $process_per_job; #set number of processed to run for each job
if ($opt_i){$process_per_job=$opt_i;}else{$process_per_job=25;}


my @clusterfile = `ls $cluster_dir`;
my @commands;

foreach my $clusterfile (@clusterfile){
  chomp $clusterfile;
  my $resultfile = $clusterfile;
  $resultfile=~s/\.txt/\.ztest/;
  my $command="/home/obig/bin/oPOSSUM/scripts/default_analysis.pl -s human -z $result_dir/$resultfile -g $cluster_dir/$clusterfile";
  push (@commands, $command);
#  print "$command\n";
}

my $i=1;
foreach my $command (@commands){
  print "$command;";
  if ($i==$process_per_job){
    print "\n";
    $i=1;
    next;
  }
$i++;
}
print "\n";
