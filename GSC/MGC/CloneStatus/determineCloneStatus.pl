#!/usr/local/bin/perl
# Yaron Butterfield
# Returns status of clones for a list of clones
use lib "/home/ybutterf/perl/lib";
use cDNA::Clones;
use Data::Dumper;
use strict;

my $outfile = "clonestatus.txt";
my $clonelist = "clonelist.txt";
open (CLONELIST,$clonelist);
open (OUTFILE,">$outfile");

my @clones = <CLONELIST>;

my $clones = Clones->new( mgc => [@clones], # 384 well
			  );
foreach my $x (sort{$a <=> $b} keys %$clones){
    print OUTFILE "$x,$clones->{$x}{'current_status_description'}\n";
}


#print Dumper($clones);
exit;

