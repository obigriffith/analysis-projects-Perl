#!/usr/local/bin/perl -w

use strict;
use Data::Dumper;

#take a list of GSE sample IDs and add tissue/series to front of sample name

#my $headerfile = "/home/obig/clustering/SAGE/processed_data/GPL4_samples_full_310304_n10cutoff_logfreq_matrix2.txt"; 
my $headerfile = "/home/obig/clustering/SAGE/processed_data/GPL4_samples_full_310304_n10cutoff_logfreq_matrix_noplus1_nulls.txt";
my $descriptionsfile = "/home/obig/clustering/SAGE/geo/GPL4_samples_full_310304.sample_classification.2.csv";
my (@new_sample_names, @cancer_samples, @normal_samples);

open (HEADER, $headerfile) or die "can't open $headerfile\n";


my $header = <HEADER>; #assumes headers are in first line
chomp $header;

my @old_sample_names = split("\t", $header);
#print Dumper (@old_sample_names);

foreach my $old_sample (@old_sample_names){
  unless ($old_sample=~/^GSM/){ #if header contains something like Gene, just add it to the new list without modification
    push (@new_sample_names, $old_sample);
    next;
  }
  #print "looking for $old_sample in $descriptionsfile\n";
  my $description = getDescription($old_sample);
  #print "found description: $description\n";
  my $new_sample = "$description"."_"."$old_sample";
  push (@new_sample_names, $new_sample)
}

#print Dumper (@new_sample_names);
my $new_header = join("\t", @new_sample_names);
print "$new_header\n";

#print list of columns that contain normal or cancer samples so that they can easily be cut from the file.
my $count = 0;
foreach my $sample (@new_sample_names){
  $count++;
  if ($sample=~/^Normal/){
    push (@normal_samples, $count);
  }
  if ($sample=~/^Cancer/){
    push (@cancer_samples, $count);
  }
}

my $cancer_samples = join (",", @cancer_samples);
my $normal_samples = join (",", @normal_samples);

print "Cancer samples are in columns:\n$cancer_samples\n";
print "Normal samples are in columns:\n$normal_samples\n";

exit;

sub getDescription{
my $old_sample = shift @_;
my $description = "tissue_cancerstate_unknown";
open (DESCRIPTIONS, $descriptionsfile) or die "can't open $descriptionsfile\n";
while (<DESCRIPTIONS>){
  if ($_=~/^\"(GSM\d+)\"\s+\"(.+)\"\s+\"(.+)\"\s+\"(.+)\"\s+\"(.+)\"/){
    my $sample_temp = $1;
    my $sample_info = $2;
    my $tissue = $3;
    my $cancer_state = $4;
    my $cell_line = $5;
    if ($sample_temp eq $old_sample){
      #print "Entry found for $old_sample: $tissue\t$cancer_state\n";
      $description = "$cancer_state"."_"."$tissue";
      last;
    }
  }
}
close DESCRIPTIONS;
return ($description);
}
