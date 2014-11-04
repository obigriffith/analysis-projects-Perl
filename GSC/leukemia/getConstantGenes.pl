#!/usr/bin/perl -w

use strict;

#This script will look for constant genes across three conditions for two times
#H13 - wildtype, 0hrs
#H14 - wildtype, 48hrs
#H15 - MLL KO, 0hrs
#H16 - MLL KO, 48hrs
#H17 - MLL KO with MLL expression reintroduced, 0 hrs
#H18 - MLL KO with MLL expression reintroduced, 48 hrs

my $infile = "/home/obig/Projects/leukemia/tm1_11_microarray/processed_data/h10_to_h20/h13_15_17.txt";
#my $infile = "/home/obig/Projects/leukemia/tm1_11_microarray/processed_data/h10_to_h20/h14_h16_h18.txt";

print "Probe\tmean_intensity\tvariance_intensity\tmean_pvalue\n";

open (INFILE, $infile) or die "can't open $infile";
my $firstline = <INFILE>; #skip title line
while (<INFILE>){
  my @array = split ("\t", $_);
  my $id = $array[0];
  unless ($array[2] eq 'P' && $array[5] eq 'P' && $array[8] eq 'P'){
    #print "$id not present across all conditions\n";
    next;
  }
  my @raw_intensities = ($array[1], $array[4], $array[7]);
  my @pvalues = ($array[3], $array[6], $array[9]);
  #Convert raw intensities into ln(intensities)
  my @ln_intensities;
  foreach my $intensity (@raw_intensities){ 
    if ($intensity <= 0){$intensity = 1;} #if value is negative or zero, set to one for logging
    my $ln_intensity = log($intensity);
    push (@ln_intensities, $ln_intensity);
  }

  #calculate mean and sd for intensities
  my $sum_intensity = 0;
  my $variance_intensity = 0;
  my $sd_intensity = 0;
  #mean
  foreach (@ln_intensities) { $sum_intensity += $_ }
  my $n = scalar(@ln_intensities);
  my $mean_intensity = $sum_intensity/$n;
  #standard deviation
  foreach (@ln_intensities) {
    my $deviation_intensity = $_ - $mean_intensity;
    $variance_intensity += $deviation_intensity**2;
  }
  $variance_intensity /= ($n - 1);
  $sd_intensity = sqrt($variance_intensity);

  #calculate mean and sd for p-values
  my $sum_pvalue = 0;
  my $variance_pvalue = 0;
  my $sd_pvalue = 0;
  #mean
  foreach (@pvalues) { $sum_pvalue += $_ }
  my $mean_pvalue = $sum_pvalue/$n;
  #standard deviation
  foreach (@pvalues) {
    my $deviation_pvalue = $_ - $mean_pvalue;
    $variance_pvalue += $deviation_pvalue**2;
  }
  $variance_pvalue /= ($n - 1);
  $sd_pvalue = sqrt($variance_pvalue);

  printf ("%s\t%.3f\t%.3f\t%.3f\n",$id,$mean_intensity,$variance_intensity,$mean_pvalue);
}
close INFILE;

