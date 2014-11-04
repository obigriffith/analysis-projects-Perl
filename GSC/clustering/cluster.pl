#!/usr/bin/perl -w

use Getopt::Std;
use Data::Dumper;
use DBI;
use lib "/home/obig/bin/Cluster/Algorithm-Cluster-1.23/local2/lib64/perl5/site_perl/5.8.0/";
#use lib "/home/pubseq/BioSw/Cluster/Algorithm-Cluster-1.22/local/lib/site_perl/5.6.1/i686-linux-ld";
use Algorithm::Cluster;
use strict;
use Benchmark;

#This script is meant to be run by cluster_wrapper.pl so that its output can be captured and summarized.

my $t1 = new Benchmark;

my $dbname = "sage_library_comparisons_01";
my $dbh = DBI->connect( 'dbi:mysql:database=' . $dbname . ';host=db01', 'viewer', 'viewer', { PrintError => 1, RaiseError => 0 } );

my (@orfname,@orfdata,@masked, @weighted);
my $i=0;
my $mask_count = 0;

if ($#ARGV !=1) {
print "cluster.pl requires two gene_ids as input (ie. cluster.pl 1 2)\n";
exit;

$|++;
$^W = 1;

}

my $tag1 = $ARGV[0];
my $tag2 = $ARGV[1];
#print "Will get data for tags $tag1 and $tag2 from database\n";

my $SQL1 = "select ratio from tag_lib_comp where FK_tag_id=\'$tag1\'";
my $sth1 = $dbh->prepare($SQL1);
$sth1->execute();
my @data1;
while (my @ary = $sth1->fetchrow_array()){
  push (@data1,$ary[0]);
}
$sth1->finish();

my $SQL2 = "select ratio from tag_lib_comp where FK_tag_id=\'$tag2\'";
my $sth2 = $dbh->prepare($SQL2);
$sth2->execute();
my @data2;
while (my @ary2 = $sth2->fetchrow_array()){
  push (@data2,$ary2[0]);
}
$sth2->finish();
$dbh->disconnect();
my $t2 = new Benchmark;

my $td = timediff($t2, $t1);
print "Database access took:",timestr($td),"\n";

$orfdata[0]  = [ @data1[1..$#data1] ];
$orfdata[1]  = [ @data2[1..$#data2] ];
for (my $i=0; $i<=1; $i++){
  for (my $j=0; $j<$#data1; $j++){
    $masked[$i][$j]=1;
  }
}

for (my $j=0; $j<$#data1; $j++){
  $weighted[$j]=1;
}

my $t3 = new Benchmark;
my $td2 = timediff($t3, $t2);
print "matrix construction took:",timestr($td2),"\n";

my %params = (
	data      =>    \@orfdata,
	mask	=>   \@masked,
	weight => \@weighted,
	applyscale =>         0,
	transpose  =>         0,
	dist       =>       'c',
	method     =>       'n',
);
my ($result, $linkdist);
($result, $linkdist) = Algorithm::Cluster::treecluster(%params);

#print Dumper ($result);
#print Dumper ($linkdist);
#print "$mask_count entries masked\n";
#}

my $t4 = new Benchmark;
my $td3 = timediff($t4, $t3);
print "Cluster analysis took:",timestr($td3),"\n";

exit;
