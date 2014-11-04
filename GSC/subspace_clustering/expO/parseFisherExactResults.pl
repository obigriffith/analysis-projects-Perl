#!/usr/bin/perl -w

use strict;

use Getopt::Std;
getopts("f:");
use vars qw($opt_f);

my $fisherExactresults=$opt_f;
my %results;
my $min_inclust_interm=2; #Set the minimum number of exps in a cluster annotated to a term to consider of interest

open (FISHERRESULTS, $fisherExactresults) or die "can't open $fisherExactresults\n";
my $headers = <FISHERRESULTS>;
while (<FISHERRESULTS>){
my @entry = split("\t", $_);
my $cluster=$entry[0];
my $term=$entry[1];
my $inclust_interm=$entry[2];
my $inclust_notinterm=$entry[3];
my $notclust_interm=$entry[4];
my $notclust_notinterm=$entry[5];
my $pvalue=$entry[6];

#print "$cluster\t$term\t$pvalue\n";
$results{$cluster}{$term}{'pvalue'}=$pvalue;
$results{$cluster}{$term}{'inclust_interm'}=$inclust_interm;
$results{$cluster}{$term}{'inclust_notinterm'}=$inclust_notinterm;
$results{$cluster}{$term}{'notclust_interm'}=$notclust_interm;
$results{$cluster}{$term}{'notclust_notinterm'}=$notclust_notinterm;
}

foreach my $cluster (sort keys %results){
  my $cluster_minpvalue=1;
  my ($best_term, $best_inclust_interm, $best_inclust_notinterm, $best_notclust_interm, $best_notclust_notinterm);
  foreach my $term (sort keys %{$results{$cluster}}){
    my $pvalue=$results{$cluster}{$term}{'pvalue'};
    my $inclust_interm=$results{$cluster}{$term}{'inclust_interm'};
    if ($inclust_interm>=$min_inclust_interm){#require some minimum number of exps annotated to a particular term (use $min_inclust_interm=1 for all results)
      if ($pvalue<$cluster_minpvalue){#Keep track of best(smallest) pvalue for the cluster
	$cluster_minpvalue=$pvalue;
	$best_term=$term;
	$best_inclust_interm=$inclust_interm;
	$best_inclust_notinterm=$results{$cluster}{$term}{'inclust_notinterm'};
	$best_notclust_interm=$results{$cluster}{$term}{'notclust_interm'};
	$best_notclust_notinterm=$results{$cluster}{$term}{'notclust_notinterm'};
      }
    }
  }
  print "$cluster\t$best_term\t$best_inclust_interm\t$best_inclust_notinterm\t$best_notclust_interm\t$best_notclust_notinterm\t$cluster_minpvalue\n";
}

