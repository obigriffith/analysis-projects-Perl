#!/usr/bin/perl -w

use strict;
use Data::Dumper;
use Storable;

my $datafile = '/home/obig/clustering/bestmatch/storables/sagetest2.storable.txt';


#Retrieve pre-loaded data from file using Storable's retrieve function.
#Expects an array with three references to @x, @y, and @r arrays
my @arrays = @{retrieve($datafile)};
my ($x_ref,$y_ref,$r_ref) = @arrays[0 .. 2];
my @x = @$x_ref;  my @y = @$y_ref;  my @r = @$r_ref;

print Dumper(@x);
print Dumper(@y);
print Dumper(@r);
exit;
