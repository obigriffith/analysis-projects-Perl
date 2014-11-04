#!/usr/local/bin/perl -w

use strict;
use Data::Dumper;
use Getopt::Std;

#Thyroid data collected from various sources and stored in a master excel file fall into several categories for mapping purposes
#(1)accession id; (2)Sage tag; (3)Affymetrix probe identifier; (4)Other (in some cases only a gene name or description is provided)

getopts("f:m:");
use vars qw($opt_f $opt_m);

my %DATA;
my $entry_count=0;

unless ($opt_f && $opt_m){&printDocs;}
my $data_summary_file=$opt_f;
my $method=$opt_m;

open (SUMMARYDATA, $data_summary_file) or die "can't open $data_summary_file\n";

#Retrieve column headings from first line
my $firstline = <SUMMARYDATA>;
chomp $firstline;
my @headers = split ("\t",$firstline);
my $num_cols=@headers;
#print Dumper (@headers);
#print "\n$num_cols columns found\n";

#Go through each line of data and store in a hash
while (<SUMMARYDATA>){
  if ($_=~/^\d+/){$entry_count++;} #If lines starts with a study number, assume it represents a valid entry
  my @data = split ("\t",$_,-1);
  my $num_entries=@data;
  my $i=0;
  my $study_number = $data[0];
  for ($i=0; $i<$num_cols; $i++){
    my $data_entry=$data[$i];
    $data_entry =~ s/\"//g; #Remove any quotes
    $data_entry =~ s/\s+$//; #Remove any trailing whitespace
    #print "$headers[$i]: \"$data_entry\"\n";
    $DATA{$study_number}{$entry_count}{$headers[$i]}=$data_entry;
  }
  unless ($num_entries==$num_cols){print "error: unexpected data format\n";exit;}
  #print "\n----end of record\n";
}
close SUMMARYDATA;
#print Dumper (%DATA);

#Now, go through hash and process into separate files for mapping purposes.
foreach my $study (sort{$a<=>$b} keys %DATA){
  foreach my $entry (sort{$a<=>$b} keys %{$DATA{$study}}){

    #for studies with accession as main identifier
    if ($DATA{$study}{$entry}{'Accession'}){
      if ($opt_m==1){
	print "$study\t$entry\t$DATA{$study}{$entry}{'Accession'}\t$DATA{$study}{$entry}{'Gene'}\t$DATA{$study}{$entry}{'Description'}\n";
      }
    }

    #for studies with probe as main identifier
    elsif ($DATA{$study}{$entry}{'Probe'}){
      if ($opt_m==2){
	print "$study\t$entry\t$DATA{$study}{$entry}{'Probe'}\t$DATA{$study}{$entry}{'Gene'}\t$DATA{$study}{$entry}{'Description'}\n";
      }
    }

    #for studies with Tag as main identifier
    elsif ($DATA{$study}{$entry}{'Tag'}){
      if ($opt_m==3){
	print "$study\t$entry\t$DATA{$study}{$entry}{'Tag'}\t$DATA{$study}{$entry}{'Gene'}\t$DATA{$study}{$entry}{'Description'}\n";
      }
    }

    #for studies with Nothing as main identifier
    else{
      if ($opt_m==4){
	print "$study\t$entry\t$DATA{$study}{$entry}{'Gene'}\t$DATA{$study}{$entry}{'Description'}\n";
      }
    }

  }
}

sub printDocs{
print "This file processes a text file produced from excel containing a summary of thyroid cancer molecular profiling studies\n";
print "usage: parseThyroidDataFile.pl -f datafile.txt -m 1\n";
print "options:
-f input file
-m method (1=Accession; 2=Probe; 3=Tag; 4=Other)\n";
exit;
}
