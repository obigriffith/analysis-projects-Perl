#!/usr/bin/perl

################### LL_to_Ensembl.pl ##################
# Given file of LL gene IDs and Pearsons, and file of LL->Ensembl associations,
# replace LLs with Ensembls (removing gene pairs when one gene is not present
# in Ensembl).
#
# Usage: LL_to_Ensembl.pl <LL/Pearson file> <LL to Ensembl file>
#
########################################################

use strict;

if (scalar(@ARGV) < 2) {
    &printDocs;
}

my %mappings;

open(MAP, $ARGV[1]) || die "Cannot open LL to Ensembl file [$ARGV[1]]";

while (<MAP>) {
    if (m/^(\S+)\t(\S+)\t/) {
	if ($2 ne "n/a") {
	    $mappings{$1} = $2;
	}
    }
    else {
	print STDERR "Cannot parse line \"$_\"\n";
    }
}

close(MAP);

open(PEARS, $ARGV[0])  || die "Cannot open LL/Pearson file [$ARGV[0]]";

while(<PEARS>) {
    if (m/^(\S+)\t(\S+)\t(\S+)$/) {
	if (defined($mappings{$1}) && defined($mappings{$2})) {
	    print "$mappings{$1}\t$mappings{$2}\t$3\n";
	}
    }
    else {
	print STDERR "Cannot parse line \"$_\"\n";
    }
}

close(PEARS);



sub printDocs {
    print"################### LL_to_Ensembl.pl ##################
# Given file of LL gene IDs and Pearsons, and file of LL->Ensembl associations,
# replace LLs with Ensembls (removing gene pairs when one gene is not present
# in Ensembl).
#
# Usage: LL_to_Ensembl.pl <LL/Pearson file> <LL to Ensembl file>
#
########################################################
";
    exit;
}
