#!/usr/bin/perl
use strict;
#my $genomic_total = 21090681654;
#my $genomic_total = 31439500806;
my $genomic_total  = 70677474252;

while(<STDIN>){
    #ENSG00000127720 chr12   81276455        81397069        1968    15586   7.91971544715447
    #
    my @a = split;
    my $sequenced = $a[5];
    my $exp = 1000000*$sequenced/$genomic_total;
    print "$a[0]\t$exp\n";
}
