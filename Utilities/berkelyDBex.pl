#!/usr/bin/perl -w
use strict;
use BerkeleyDB;
use Data::Dumper;

my $file = "/gscuser/ogriffit/temp/indels_pindel.vcf";
open (FILE2, "$file") or die "can't open $file\n"; 

# Make %db an on-disk database stored in database.dbm. Create file if needed
tie my %hash1, 'BerkeleyDB::Hash', -Filename => "database.dbm", -Flags => DB_CREATE or die "Couldn't tie database: $BerkeleyDB::Error";

#Read through input file and set contents to hash as normal
while(<FILE2>){
  if ($_=~/^\#/){next;}
  my @line = split(/\s+/,$_);
  $hash1{$line[3]} = $line[3]."\n".$line[6]."\n";
}
close(FILE2);

#Retrieve information from hash as normal
for my $key (keys %hash1) {
  print "$key -> $hash1{$key}\n";  # iterate values
}

#Once finished with it, you can delete the BerkeleyDB data structure and corresponding file on file system
%hash1 = ();
unlink("database.dbm"); 

