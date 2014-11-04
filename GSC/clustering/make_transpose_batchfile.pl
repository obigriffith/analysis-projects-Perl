#!/usr/local/bin/perl

use strict;

my $transpose_script = "/home/obig/bin/Cluster/Algorithm-Cluster-1.23/transpose_large_matrix.pl";
my $datafile = "/home/obig/bin/Cluster/Algorithm-Cluster-1.23/sagedata/ratios.all5000";
my $output_dir = "/home/obig/bin/Cluster/Algorithm-Cluster-1.23/sagedata/transposed";

my $cols = 67798;
my $i = 1;
my $j = 1;
my $k = 1;
my $start = 0;
my $end = 0;

for ($i = 1; $i <= $cols; $i++){
  if ($i >= $k*100){
    $start = $end+1;
    $end = $start+99;
    print "job$k".":$transpose_script -i $datafile -o $output_dir/ratios_transposed.$k -s $start -e $end".":1:1\n";
    $k++;
    $j=1;
  }
  $j++;
}
print "job$k".":$transpose_script -i $datafile -o $output_dir/ratios_transposed.$k -s $end -e $cols".":1:1\n";

exit;
