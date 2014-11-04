#!/usr/local/bin/perl56

use strict;

my $infile = "/home/pubseq/BioSw/Cluster/Algorithm-Cluster-1.22/data/fly.clean";
my $outfile = "/home/pubseq/BioSw/Cluster/Algorithm-Cluster-1.22/data/fly.clean2";
my $mapfile = "/home/pubseq/BioSw/Cluster/Algorithm-Cluster-1.22/data/cg_fbgn.txt";
my $logfile = "/home/pubseq/BioSw/Cluster/Algorithm-Cluster-1.22/data/FBGN_to_CG.log";

my @missing;
my $missing_count = 0;
my $id_count = 0;
my $name_count = 0;

open (INFILE, $infile);
open (OUTFILE, ">$outfile");
open (LOGFILE, ">$logfile");

#get first line containing column headers
my $firstline = <INFILE>;
print OUTFILE $firstline;

while(<INFILE>){
  my $line = $_;
  if ($line=~/^(FBGN\d+)\t.*/){
    my $FBGN = $1;
    my $gene_name = &getGeneName($FBGN);
    print "$FBGN\t$gene_name\n";
    $id_count++;
    if ($gene_name eq "missing"){
      print OUTFILE $line;
    }else{
      $line=~s/^$FBGN/$gene_name/;
      print OUTFILE $line;
    }
  }
}
print "\n\n$id_count Ids searched for\n$name_count Ids found\n$missing_count Ids missing\n";

print LOGFILE "The following $missing_count FBGN Ids could not be found in $mapfile\n";
foreach my $missing (@missing){
  print LOGFILE "$missing\n";
}

close INFILE;
close OUTFILE;
close LOGFILE;
exit;

sub getGeneName{
#First check complete LocusLink list
my $FBGN = shift @_;
my $gene_name;
my $check = 0;
open (MAPFILE, $mapfile);
while (<MAPFILE>){
  if ($_=~/^(\w+)\s+(\w+)\s+(\w+)\s+.*/){
    my $name = $1;
    my $FBGN_temp = $3;
    $FBGN_temp=~tr/[a-z]/[A-Z]/;
    if ($FBGN_temp eq $FBGN){
      $gene_name = $name;
      $check = 1;
      $name_count++;
      last;
    }
  }
}
#if still not found, print an error and exit
if ($check==0){
#  print "$FBGN not found\n";
  $missing_count++;
  push (@missing, $FBGN);
  $gene_name = "missing";
}
close MAPFILE;
return($gene_name);
}
