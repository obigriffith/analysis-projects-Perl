#!/usr/bin/perl -w

use Getopt::Std;
use Data::Dumper;
use DBI;
use lib "/home/obig/bin/Cluster/Algorithm-Cluster-1.23/local2/lib64/perl5/site_perl/5.8.0/";
#use lib "/home/pubseq/BioSw/Cluster/Algorithm-Cluster-1.22/local/lib/site_perl/5.6.1/i686-linux-ld";
use Algorithm::Cluster;
use strict;
use Benchmark;

#This script is meant to be run by cluster_wrapper.pl so that its output can be captured and summarized.

my $t1 = new Benchmark;
my $tag_file = "/home/sage/clustering/matrix/all_tags.tab";
my $datafile = "/home/obig/bin/Cluster/Algorithm-Cluster-1.23/sagedata/ratios.all5000";

my (@orfname,@orfdata,@masked, @weighted);
my $i=0;
my $mask_count = 0;

$|++;
$^W = 1;

#Need to change this structure so that it doesn't repeat calculations

open (DATA1, "$datafile") or die "can't open $datafile\n";
my $firstline = <DATA1>;  # Skip the title line
while (<DATA1>){
  if (/^$/) {next;}
  chomp(my $line = $_);
  my @data1 = split /\t/, $line, -1;
  open (DATA2, "$datafile") or die "can't open $datafile\n";
  my $firstline = <DATA2>;  # Skip the title line
  while (<DATA2>){
    if (/^$/) {next;}
    chomp(my $line = $_);
    my @data2 = split /\t/, $line, -1;
    &getPearson(\@data1, \@data2)
  }
  close DATA2;
}
close DATA1;

exit;


sub getPearson{
my $data1_ref = shift @_;
my $data2_ref = shift @_;
my @data1 = @$data1_ref;
my @data2 = @$data2_ref;

my $t2 = new Benchmark;
#Create data, mask, and weight matrices for cluster.c
$orfname[0]  =   $data1[0];
$orfname[1]  =   $data2[0];
$orfdata[0]  = [ @data1[1..$#data1] ];
$orfdata[1]  = [ @data2[1..$#data2] ];
for (my $i=0; $i<=1; $i++){
  for (my $j=0; $j<$#data1; $j++){
    $masked[$i][$j]=1;
  }
}

for (my $j=0; $j<$#data1; $j++){
  $weighted[$j]=1;
}

my $t3 = new Benchmark;
my $td2 = timediff($t3, $t2);
print "matrix construction took:",timestr($td2),"\n";

my %params = (
	data      =>    \@orfdata,
	mask	=>   \@masked,
	weight => \@weighted,
	applyscale =>         0,
	transpose  =>         0,
	dist       =>       'c',
	method     =>       'n',
);
my ($result, $linkdist);
($result, $linkdist) = Algorithm::Cluster::treecluster(%params);

#print Dumper ($result);
#print Dumper ($linkdist);
#print "$mask_count entries masked\n";
#}

my $t4 = new Benchmark;
my $td3 = timediff($t4, $t3);
print "Cluster analysis took:",timestr($td3),"\n";
}

