#!/usr/local/bin/perl -w

use strict;
use Getopt::Std;

getopts("d:o:t:");
use vars qw($opt_d $opt_o $opt_t);
use Data::Dumper;

my $pattern_dir = $opt_d;#This script assumes you have named pattern files like 'pattern1' and placed them all in the data dir
my $output_dir = $opt_o;#specify directory to write config files (one for each pattern file)
my $totalfile = $opt_t;#assumes total file is in data dir

my @files = `ls $pattern_dir`;
my @patterns;
foreach my $file (@files){
  chomp $file;
  if ($file=~/pattern\d+$/){
    push (@patterns, $file);
  }
}

foreach my $pattern (@patterns){
my $configfile = "$output_dir"."$pattern".".config";
open (CONFIG, ">$configfile") or die "can't open $configfile\n";
print CONFIG "DATA = $pattern_dir
TOTALFILE = $totalfile
LIST = $pattern
DATASOURCE = all
ENHANCED = true
DBXREF = true
SYNONYM = true
ORGANISM = 9606
EVIDENCECODE = all
RANDOMS = 100
THRESHOLD = 0.1
TIMESERIESTHRESHOLD = 0.1
USER = viewer
PASSWORD = viewer
DATABASE = jdbc:mysql://db01/GO
DRIVER = com.mysql.jdbc.Driver
TF = 0
CIM = 0
ROOTCATEGORY = GO:0008150
LOGFILENAME = HTGM.DEBUG
STATUSFILENAME = RETURNCODE
";

close CONFIG;
}
