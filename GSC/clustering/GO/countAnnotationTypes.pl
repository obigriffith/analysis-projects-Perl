#!/usr/local/bin/perl -w

use strict;

my %Annotations;
my %IEP_LIST;

while (<>){
  my @entries = split (/\t/, $_);
  my $DB_Object_ID=$entries[1];
  my $GO_ID=$entries[4];
  my $evidence=$entries[6];
  my $aspect=$entries[8]; #Process, Function or Cellular localization
  #print "$DB_Object_ID assigned to $GO_ID with $evidence evidence\n";
  $Annotations{$DB_Object_ID}{$GO_ID}{$evidence}=$aspect;
}

foreach my $DB_Object_ID (sort keys %Annotations){
  foreach my $GO_ID (sort keys %{$Annotations{$DB_Object_ID}}){
    foreach my $evidence (sort keys %{$Annotations{$DB_Object_ID}{$GO_ID}}){
      my $aspect=$Annotations{$DB_Object_ID}{$GO_ID}{$evidence};
#      if ($aspect eq 'C'){ #I'm currently only interested in genes with BP annotations based on IEP
      if ($evidence eq 'IEP' && $aspect eq 'P'){ #I'm currently only interested in genes with BP annotations based on IEP
	$IEP_LIST{$DB_Object_ID}{$GO_ID}++; #create new hash for annotations that meet condition
	#print "$DB_Object_ID assigned to $GO_ID with $evidence evidence in $aspect category\n";
      }
    }
  }
}
my $genecount = 0;
print "The following genes were found to have annotations based on IEP\n";
foreach my $IEP_entry (sort keys %IEP_LIST){
  $genecount++;
  foreach my $GO_ID (sort keys %{$IEP_LIST{$IEP_entry}}){
#  print "\n$IEP_entry -> $GO_ID\n";
    foreach my $evidence (sort keys %{$Annotations{$IEP_entry}{$GO_ID}}){ #For gene annotations with IEP evidence get any other evidence
      my $aspect=$Annotations{$IEP_entry}{$GO_ID}{$evidence};
      print "$IEP_entry assigned to $GO_ID with $evidence evidence $aspect category\n";
    }
  }
}

print "\n$genecount genes found\n";

exit;
