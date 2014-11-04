#!/usr/bin/perl


#############################################################################
#                                                                           #
#     gotoolbox-distmat.pl, part of the                                     #
#     GOToolBox version 1.0 (author : D. MARTIN, CNRS, France)              #
#     Copyright 2004                                                        #
#                                                                           #
#                                                                           #
#     This program is free software; you can redistribute it and/or modify  #
#     it under the terms of the GNU General Public License as published by  #
#     the Free Software Foundation; either version 2 of the License, or     #
#     (at your option) any later version.                                   #
#                                                                           #
#     This program is distributed in the hope that it will be useful,       #
#     but WITHOUT ANY WARRANTY; without even the implied warranty of        #
#     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the         #
#     GNU General Public License for more details.                          #
#                                                                           #
#############################################################################

use strict;
use Data::Dumper;

if ($#ARGV != 1) {
    die "syntax : $0 gtb_file outfile.mat\n";
}
open (F, $ARGV[0]) or die "can not open $ARGV[0] -> aborting\n";
my @file_content = <F>;
close F;

open (O, ">$ARGV[1]") or die "can not open $ARGV[1] -> aborting\n";

###############
### M A I N ###
###############

my ($DATASET, $TERMS, $ONTOS, $REFANN, $ASSOCIATION) = &GTB2TLF(\@file_content);
my @temp = keys(%$TERMS);
my $NBTERMS = $#temp+1; @temp=();

# generate the distance matrix
my @lkeys = keys %$ASSOCIATION;
my ($ii, $oo, %MATRIX);
for ($ii=0; $ii<=$#lkeys; $ii++) {
  print "calculating all distances for $ii:$lkeys[$ii]\n";
    for ($oo=$ii; $oo<=$#lkeys; $oo++) {
	my $c1 = $lkeys[$ii];
	my $c2 = $lkeys[$oo];
	my $case = &calc_dist(\%$ASSOCIATION, \$c1, \$c2);
	$MATRIX{$lkeys[$ii]}[$oo] = sprintf ("%5.4f", $case);
	$MATRIX{$lkeys[$oo]}[$ii] = sprintf ("%5.4f", $case);
    }
}

# write the distance matrix in a file
#First print gene labels across the cols
for ($ii=0; $ii<=$#lkeys; $ii++) {
    print O "\t".$lkeys[$ii];
  }
print O "\n";

#now print the gene label at beginning of row followed by all data
for ($ii=0; $ii<=$#lkeys; $ii++) {
    print O $lkeys[$ii]."\t";
    for ($oo=0; $oo<$#lkeys; $oo++) {
 	print O $MATRIX{$lkeys[$ii]}[$oo]."\t";
    }
    print O $MATRIX{$lkeys[$ii]}[$#lkeys]."\n";
}

#print Dumper($ASSOCIATION);

##############
## ROUTINES ##
############## 

sub GTB2TLF {
    my $inf = shift;
    my @file_content = @$inf;
    my ($i, %DATASET, %TERMS, %ONTOS, $REFANN, %ASSOCIATION);

    for ($i=0; $i<=$#file_content; $i++) {
	if ($file_content[$i] =~ /^\[ GENE name\=\'([^\']+)\' id\=\'([^\']+)\' input\=\'([^\']*)\' \]/) {
#	    my $current_g=$1; $i++;
	    my $current_g=$2; $i++; #Use Gene_ID instead of Gene_Name
	    while ($file_content[$i] !~ /^\[ \/GENE \]/) {
		if ($file_content[$i] =~ /^\[ ([a-zA-Z]+) id\=\'([^\']+)\' lev\=\'([^\']+)\' term\=\'([^\']+)\' onto\=\'([^\']+)\'/) {
		    my $id=$2;
		    my $term=$4;
		    my $onto=$5;
		    push @{$ASSOCIATION{$current_g}}, $id;
		    if (!exists($DATASET{$id})) {
			$DATASET{$id}=1;
			$TERMS{$id}=$term;
			$ONTOS{$id}=$onto;
		    } else {
			$DATASET{$id}++;
		    }
		}
		$i++;
	    }
	}
	if ($file_content[$i] =~ /^\[ ANNOTATED_GENES \: ([0-9]+) \]/) {
	    $REFANN = $1;
	}
    }

    return(\%DATASET, \%TERMS, \%ONTOS, \$REFANN, \%ASSOCIATION);
}


sub calc_dist {
    my $ASSOC = shift;
    my $set1= shift; 
    my $set2= shift;
    my $termes_communs=0;  
    foreach my $k (@{$$ASSOC{$$set1}}) {
	foreach my $q (@{$$ASSOC{$$set2}}) {
 	    if ($k eq $q) {
 		$termes_communs++;
 	    }
 	}
    }
    my $spec1=(($#{@$ASSOC{$$set1}}+1)-$termes_communs);
    my $spec2=(($#{@$ASSOC{$$set2}}+1)-$termes_communs);
    my $cd_dist=($spec1+$spec2)/(($spec1+$spec2+$termes_communs)+$termes_communs); # distance de Dice
    return($cd_dist);
}

sub print_mat {
    my $mat = shift;
    my $k = shift;
    my $o;
    foreach (@$k) {
	print $_."<br>";
	for ($o = 0; $o <= $#{$$mat{$_}}; $o++) {
	    print $$mat{$_}[$o]."\t";
	}
	print "<br>";
    }
}
