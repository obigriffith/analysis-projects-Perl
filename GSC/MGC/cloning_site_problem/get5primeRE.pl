#!/usr/local/bin/perl -w

use strict;

#For a list of clones and libraries, searches the all_lib.txt file and determines the
#restriction enzyme used

my $clonelist = "IRAK89_clones_libraries.txt";
my $libraryinfo = "all_lib.txt";
my $summary = "summary.txt";
my %HoH;

open (CLONELIST,$clonelist) or die "can't open $clonelist";
open (SUMMARY,">$summary") or die "can't open $summary";

while (<CLONELIST>){
  my $line = $_;
  if ($line =~ /^\|\s(\d+)\s+\|\s(\d+)\s+\|\s(\w+)\s+\|/){
#    print "Clone: $1  Library:$2\n";
    my $clone = $1;
    my $library = $2;
    my $quadrant = $3;
    my $enzyme = Determine5primeRE($library);
    EnterDataintoHash($clone,$library,$quadrant,$enzyme);
  }
}

PrintHash();

close CLONELIST;
close SUMMARY;

exit;

sub Determine5primeRE{
my $linestatus = 0;
my $enzyme;

open (LIBINFO,$libraryinfo) or die "can't open $libraryinfo";
my $library = shift @_;
while (<LIBINFO>){
  my $line = $_;
  if ($line =~ /^LIBRARY\s+ID:\s+(\d+)\s*\n/){
    my $libtemp = $1;
    if ($library eq $libtemp){
#      print "found $library equal to $libtemp in the library file\n";
      $linestatus = 1;
    }
  }
  if ($linestatus == 1){
    if ($line =~ /RE_5\':\s+(\w+)\s*\n/){
      $enzyme = $1;
#      print "Found the 5 prime enzyme used: $enzyme\n";
      last;
    }
  }
}
close LIBINFO;
return($enzyme);
}


sub EnterDataintoHash{
my $clone = shift @_;
my $library = shift @_;
my $quadrant = shift @_;
my $enzyme = shift @_;

#$HoH{$quadrant}{$library}{$enzyme}{$clone}=1;
$HoH{$enzyme}{$quadrant}{$clone}=1;

}

sub PrintHash{
#  foreach my $quadrant(sort keys %HoH){
#    foreach my $library(sort{$a<=>$b} keys %{ $HoH{$quadrant} } ){
#      foreach my $enzyme(sort keys %{ $HoH{$quadrant}{$library} } ){
#	foreach my $clone(sort keys %{ $HoH{$quadrant}{$library}{$enzyme} } ){
#	  print "$quadrant  $library  $enzyme  $clone\n";
#	}
#      }
#    }
#  }

  foreach my $enzyme(sort keys %HoH){
    foreach my $quadrant (sort keys %{ $HoH{$enzyme} } ){
      foreach my $clone (sort keys %{ $HoH{$enzyme}{$quadrant} } ){
	print SUMMARY "$quadrant\t$clone\t$enzyme\n";
      }
    }
  }


}
