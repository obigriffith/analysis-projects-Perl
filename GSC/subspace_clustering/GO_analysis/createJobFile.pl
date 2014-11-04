#!/usr/local/bin/perl -w

use strict;
use Getopt::Std;

getopts("d:o:");
use vars qw($opt_d $opt_o);
use Data::Dumper;

my $config_dir = $opt_d;#This script assumes you have named config files like 'pattern1.config' and placed them all in the data dir
my $output_file = $opt_o;#specify file to write jobs to

my @files = `ls $config_dir`;
my @configs;
foreach my $file (@files){
  chomp $file;
  if ($file=~/\w+\.config$/){
    push (@configs, $file);
  }
}



open (JOBFILE, ">$output_file") or die "can't open $output_file\n";
foreach my $config (@configs){
my $configfile = "$config_dir"."$config";
my $command = "/home/rvarhol/root/bin/java -cp /home/rvarhol/Programs/GoMiner/hi-thruput/scripts/gominer.jar -Xmx1G gov.nih.nci.lmp.gominer.HTGMCommand $configfile";
print "$command\n";
print JOBFILE "$command\n";
}
close JOBFILE;
