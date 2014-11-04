#!/usr/local/bin/perl56 -w
#!/usr/bin/perl -w

use strict;
use Data::Dumper;
use Getopt::Std;

getopts("f:d:c");
use vars qw($opt_f $opt_d $opt_c);

my $i=1;
my $prot_cluster_file=$opt_f;
my $dest_dir=$opt_d;

#Opossum accepts individual files for each list to be tested with one ENSG per line

open (PROT_CLUSTERFILE, $prot_cluster_file) or die "can't open $prot_cluster_file\n";
while (<PROT_CLUSTERFILE>){
  chomp $_;
  my $clusterfile;
  my @prot_cluster = split ("\t", $_);
  if ($opt_c){ #If opt_c option is specified, take clustername from first column of file and use to name output file
    my $cluster_name=shift(@prot_cluster);
    $clusterfile = "$dest_dir/"."$cluster_name".".txt";
  }else{
    $clusterfile = "$dest_dir/"."$i".".txt";
  }
  open (CLUSTERFILE, ">$clusterfile") or die "can't open $clusterfile\n";
  print CLUSTERFILE join("\n", @prot_cluster),"\n";
  print $clusterfile, "\n", join("\n", @prot_cluster),"\n\n";
  close CLUSTERFILE;
  $i++;
}

close PROT_CLUSTERFILE;
