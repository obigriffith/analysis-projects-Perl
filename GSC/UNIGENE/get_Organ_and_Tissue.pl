#!/usr/local/bin/perl -w

use strict;
my $libraryfile = "all_lib.txt";
my $lucasfile = "lib_rank.txt";
my $outfile = "Lucas_lib_organ_and_tissues.txt";
my $library;
my $tissue;
my $organ;
my $rank;
open (OUTFILE, ">$outfile") or die "can't open $outfile";
open (LUCASFILE, $lucasfile) or die "can't open $lucasfile";

print OUTFILE "Rank\tLibrary\tOrgan\tTissue\n";
while (<LUCASFILE>){
  my $line = $_;
  if ($line =~ /^(\w+)\t+(\d+)/){
    $library = $1;
    $rank = $2;
  }
  ($tissue, $organ) = getTissueforLibrary($library);

  print OUTFILE "$rank\t$library\t$organ\t$tissue\n";
  print "$rank\t$library\t$organ\t$tissue\n";
}
close LUCASFILE;
close OUTFILE;
exit;

######################################################################
sub getTissueforLibrary{
my $library = shift @_;
my $tissue = "n/a";
my $organ = "n/a";
my $linestatus = 0;
my $tissuetemp;
my $organtemp;

#$library  =~ s/\s//g;
if ($library){
#  print "Library to look for tissue $library\n";
  open (LIBRARIES,$libraryfile) or die "can't open $libraryfile";
  while (<LIBRARIES>){
    my $line = $_;
#    print "Line: $line";
    if ($line =~ /^NAME:\s+(.+)\n/){
      my $libtemp = $1;
      chomp $libtemp;
      $libtemp =~ s/\s//g;
#      print "$library $libtemp\n";
      if ($library eq $libtemp){
#	print OUTFILE "found $library in the library file\n";
	$linestatus = 1;
      }
    }
    if ($line =~ /^ORGAN:\s+(.+)\s+\n/){
      $organtemp = $1;
      if ($linestatus == 1){
	$organ = $organtemp;
	$linestatus = 2;
      }
    }

    if ($line =~ /^\s+\`\-\-\-\s+TISSUE:\s+(.+)\s+\n/){
#      print "found a tissue: $line\n";
      $tissuetemp = $1;
      if ($linestatus == 2){
	$tissue = $tissuetemp;
#	print OUTFILE "Library: $library Tissue: $tissue\n";
	$linestatus = 0;
      }
    }
  }
}
close LIBRARIES;
chomp $tissue;
chomp $organ;
return($tissue,$organ);
}

