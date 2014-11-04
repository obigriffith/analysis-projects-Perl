#!/usr/local/bin/perl -w

use strict;

my %Annotations;
my %EVIDENCE;

while (<>){
  my @entries = split (/\t/, $_);
  my $DB_Object_ID=$entries[1];
  my $GO_ID=$entries[4];
  my $evidence=$entries[6]; #evidence code
  my $aspect=$entries[8]; #Process, Function or Cellular localization
  print "$DB_Object_ID assigned to $GO_ID with $evidence evidence\n";
  $Annotations{$DB_Object_ID}{$GO_ID}{$evidence}=$aspect;
}

foreach my $DB_Object_ID (sort keys %Annotations){
  foreach my $GO_ID (sort keys %{$Annotations{$DB_Object_ID}}){
    foreach my $evidence (sort keys %{$Annotations{$DB_Object_ID}{$GO_ID}}){
      my $aspect=$Annotations{$DB_Object_ID}{$GO_ID}{$evidence};
      if ($aspect eq 'P'){ #I'm currently only interested in BP annotations
	$EVIDENCE{$evidence}++; #create new hash for annotations that meet condition
	#print "$DB_Object_ID assigned to $GO_ID with $evidence evidence in $aspect category\n";
      }
    }
  }
}

foreach my $evidence (sort keys %EVIDENCE){
  print "$evidence\t$EVIDENCE{$evidence}\n";
}


exit;
