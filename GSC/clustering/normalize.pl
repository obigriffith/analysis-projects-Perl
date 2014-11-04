#!/usr/local/bin/perl -w

use strict;
use lib "/home/obig/lib/perl/Statistics-Descriptive-2.6";
use Statistics::Descriptive;
use Data::Dumper;

my @array =  (

        [ 2.1, -1.2, 1.5, 2.5, 1.7, 2.3, 3.5, 0.6, 2.3 ],
        [ 1.4, 1.3, -1.7, 1.1, 3.2, 2.8, 2.0, 3.6, 4.3 ],
        [ 1.1, 1.5, 1.9, 2.3, 1.2, 1.5, 2.5, 2.9, 1.7 ],
        [ 3.1, 1.9, 1.1, -2.3, 1.2, 1.5, 2.5, 1.0, 1.7 ],
        [ 1.4, 1.3, -1.7, 1.1, 3.2, 2.9, 2.0, 1.1, 4.3 ],
        [ 1.6, -1.2, 1.5, 2.5, 1.7, 2.3, 3.5, 1.2, 2.3 ],
        [ 5.1, 5.2, 1.7, 1.0, 1.3, 1.7, 2.2, 1.3, 3.2 ]);

#Change the following to determine array size
#my $array_width_ref = $array[0];
#my @array_width2 = @$array_width_ref;
#my @array_width2 = @{$array[0]};
#print Dumper (@array_width2);
#my $array_width = $#array_width2 + 1;

my $array_length = $#array + 1;
my $array_width = $#{@{$array[0]}}+1;

print "Array dimensions?: depth $array_length and width $array_width\n";

my $i=0;
#For each column (ie. experiment) determine the median and interquartile range
for ($i =0; $i <$array_width; $i++){ 
#  print "column: $i\n";
  my @vector;
  my $j=0;
  for ($j =0; $j <$array_length; $j++){
#    print "row: $j\n";
    if ($array[$j][$i]){ #add array element to vector if it has a value
      push (@vector,$array[$j][$i]);
    }
  }
  my $stat = Statistics::Descriptive::Full->new();
  print Dumper(@vector);
  $stat->add_data(\@vector);
  $stat->sort_data();
  my @sorted = $stat->get_data();
  my $quartile_1st = $stat->percentile(25);
  my $quartile_3rd = $stat->percentile(75);
  my $median = $stat->median();
  my $interquartile = $quartile_3rd - $quartile_1st;
  print "data: @sorted\n";
  print "1st_quart: $quartile_1st, 3rd_quart: $quartile_3rd, interquartile range: $interquartile, median: $median\n\n";
#  print "median: $median\n";
}

exit;

