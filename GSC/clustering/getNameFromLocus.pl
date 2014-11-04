#!/usr/local/bin/perl56

use strict;

my $infile = "/home/pubseq/BioSw/Cluster/Algorithm-Cluster-1.22/data/human.clean3";
my $outfile = "/home/pubseq/BioSw/Cluster/Algorithm-Cluster-1.22/data/human.clean4";
my $locus_file = "/home/pubseq/BioSw/Cluster/Algorithm-Cluster-1.22/data/LocusLink_Hs_complete_300903.txt";
my $locus_history = "/home/pubseq/BioSw/Cluster/Algorithm-Cluster-1.22/data/LocusID_history_300903.txt";
my $logfile = "/home/pubseq/BioSw/Cluster/Algorithm-Cluster-1.22/data/LocusLink.log";
my $id_count = 0;
my $name_count = 0;
my $replaced_count = 0;
my $missing_count = 0;

open (INFILE, $infile);
open (LOGFILE, ">$logfile");
open (OUTFILE, ">$outfile");
my @missing;
my @replaced;

#get first line containing column headers
my $firstline = <INFILE>;
print OUTFILE $firstline;

while(<INFILE>){
  my $line = $_;
  if ($line=~/^(\d+)\t.*/){
    my $locus_link = $1;
    my $gene_name = &getGeneName($locus_link);
    print "$locus_link\t$gene_name\n";
    unless ($gene_name eq "missing"){
      $line=~s/^$locus_link/$gene_name/;
      print OUTFILE $line;
    }
    $id_count++;
  }
}
close INFILE;

print LOGFILE "\n-----------Summary-------------\n";
print LOGFILE "$id_count ids found in $infile\n";
print LOGFILE "$name_count gene names found in locus file or history file\n";
print LOGFILE "The following $missing_count ids still not accounted for:\n";
foreach my $missing (@missing){
  print LOGFILE "$missing\n";
}
print LOGFILE "\n";
print LOGFILE "The following $replaced_count ids have been replaced with another:\n";
print LOGFILE "Old_Locus\tOld_Gene\tNew_Locus\tNew_Gene\tDate\tTime\n";

foreach my $replaced (@replaced){
  print LOGFILE "$replaced";
}

close INFILE;
close LOGFILE;
close OUTFILE;
exit;

sub getGeneName{
#First check complete LocusLink list
my $locus_link = shift @_;
my $gene_name;
my $check = 0;
open (LOCUS, $locus_file);
while (<LOCUS>){
  if ($_=~/^(\d+)\s+(\S+)\s+/){
    my $locus_temp = $1;
    my $name = $2;
    if ($locus_temp == $locus_link){
      $gene_name = $name;
      $check = 1;
      $name_count++;
      last;
    }
  }
}
close LOCUS;
#If no LocusID was found in the complete list,check to see if this LocusLink has changed in the Locus History file
if ($check==0){
  open (LOCUSHISTORY, $locus_history);
  while (<LOCUSHISTORY>){
    my $line = $_;
    if ($line=~/^(\d+)\s+(\S+)\s+(\d+)\s+(\S+)\s+/){
      my $locus_temp = $1;
      my $old_gene_name = $2;
      my $new_locus = $3;
      my $name = $4;
      if ($locus_temp == $locus_link){
	$gene_name = $name;
	print "$locus_link replaced by $new_locus with gene name: $gene_name\n";
	push (@replaced, $line);
	$check = 1;
	$name_count++;
	$replaced_count++;
	last;
      }
    }
  }
  close LOCUSHISTORY;
}
#if still not found, print an error and exit
if ($check==0){
  print "$locus_link not found\n";
  $missing_count++;
  push (@missing, $locus_link);
  $gene_name = "missing";
}
return($gene_name);
}

