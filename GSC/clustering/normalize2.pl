#!/usr/local/bin/perl56

use strict;
use Data::Dumper;
use lib "/home/pubseq/BioSw/Cluster/Algorithm-Cluster-1.22/local/lib/site_perl/5.6.1/i686-linux-ld";
use Algorithm::Cluster;

$|++;

$^W = 1;

my $data =  [

        [ '', 2.1, 1.5, 2.5, 1.7, 2.3, 3.5, 0.6, 2.3 ],
        [ 2.1, 2.1, 1.5, 2.5, '', 2.3, 3.5, 0.6, 2.3 ],
        [ 1.4, 1.4, -1.7, 1.1, 3.2, 2.8, 2.0, 3.6, 4.3 ],
        [ 1.1, 1.1, 1.9, '', 1.2, 1.5, 2.5, 2.9, 1.7 ],
        [ 3.1, 3.1, 1.1, -2.3, 1.2, 1.5, 2.5, 1.0, 1.7 ],
        [ 1.4, 1.3, -1.7, 1.1, 3.2, 2.9, 2.0, 1.1, 4.3 ],
        [ 1.6, -1.2, 1.5, 2.5, 1.7, 2.3, 3.5, 1.2, 2.3 ],
        [ 5.1, 5.2, 1.7, 1.0, 1.3, 1.7, 2.2, 1.3, 3.2 ],
];



my $mask =  [

        [ 1, 1, 1, 1, 1, 1, 1, 1, 1 ],
        [ 1, 1, 1, 1, 1, 1, 1, 1, 1 ],
        [ 1, 1, 1, 1, 1, 1, 1, 1, 1 ],
        [ 1, 1, 1, 1, 1, 1, 1, 1, 1 ],
        [ 1, 1, 1, 1, 1, 1, 1, 1, 1 ],
        [ 1, 1, 1, 1, 1, 1, 1, 1, 1 ],
        [ 1, 1, 1, 1, 1, 1, 1, 1, 1 ],
        [ 1, 1, 1, 1, 1, 1, 1, 1, 1 ],

];

my $weight = [ 1, 1, 1, 1, 1, 1, 1, 1, 1 ];

my %params = (
	data      =>    $data,
	mask      =>    $mask,
	weight    =>    $weight,
	applyscale =>         0,
	transpose  =>         0,
	dist       =>       'c',
	method     =>       'a',
);

my ($result, $linkdist);
my ($i,$j);

my $normalized = Algorithm::Cluster::normalize1(%params);

$params{data}=$normalized;  #reset data param to use normalized data.

($result, $linkdist) = Algorithm::Cluster::treecluster(%params);
#print Dumper($normalized);

$i=0;
foreach(@{$result}) {
	printf("%2d: %3d %3d %7.3f\n",$i,$_->[0],$_->[1],$linkdist->[$i]);
	++$i;
}



exit;

