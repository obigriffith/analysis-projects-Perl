#!/usr/bin/perl -w
#!/usr/local/bin/perl -w

use DBI;
use strict;
use Data::Dumper;

$| = 1;

#-----DATABASE CONNECTION-----------------
my $server = "db01";
my $user_name = "viewer";
my $password = "viewer";

#my $db_name = "cisred_1_1b";
#my $db_name = "cisred_1_1c";
my $db_name = "cisred_1_2a";
#my $db_name = "cisred_1_2c"; #The cluster information needs to be updated for this version - it is not accurate

my $dsn = "DBI:mysql:$db_name:$server";
#------------------------------------------

my $dbh = DBI->connect($dsn,$user_name,$password,{PrintError=>1}) || die;

#load list of cluster/accession ids
my @Accs;
my $accessions = "CommonMotifGeneClusters_cisred_1_2a.coexpression.gt025.txt";
open (ACCESSIONS,$accessions) or die "can't open $accessions\n";
while (<ACCESSIONS>){
  if ($_=~/^(\S+)\s+/){
    push (@Accs,$1);
  }
}

# get all features and their corresponding Ensembl IDs
#print "Getting features from $db_name:$server\n";
my %FeatureInfo;
my $sth1 = $dbh->prepare( "SELECT f.id,sequence,source_annotation,source_start,f.score,f.consensus FROM sitesequences s, features f where f.id=s.feature_id and f.ensembl_gene_id=s.source_annotation" ) || die "error in pop table";
$sth1->execute() || die "error in pop table";
while ( my @row = $sth1->fetchrow_array() ){
  my $feature_id = $row[0];
  my $feature_target_sequence=$row[1];
  my $gene = $row[2];
  my $gene_start=$row[3];
  my $feature_score=$row[4];
my $feature_consensus=$row[5];
  $FeatureInfo{$feature_id}{'gene'} = $gene;
  $FeatureInfo{$feature_id}{'sequence'} = $feature_target_sequence;
  $FeatureInfo{$feature_id}{'genestart'} = $gene_start;
  $FeatureInfo{$feature_id}{'score'} = $feature_score;
  $FeatureInfo{$feature_id}{'consensus'} = $feature_consensus;
  #print "$feature_id $gene\n";
}
$sth1->finish();

#Get all feature clusters
#print "Getting feature clusters\n";
my %MotifClusters;
my %ClusterFeatures;
my $sth2 = $dbh->prepare( "SELECT accession_id, feature_id FROM accession;" ) || die "error in pop table";
$sth2->execute() || die "error in pop table";
 while ( my @row = $sth2->fetchrow_array() ){
  my $cluster_id = $row[0];
  my $feature_id = $row[1];
  $MotifClusters{$cluster_id}++; #Keep track of size of each cluster;
  $ClusterFeatures{$cluster_id}{$feature_id}++; #There should only ever be one entry for each cluster/feature combination
#  print "$cluster_id $feature_id\n";
}
$sth2->finish();
$dbh->disconnect();

#Go through each accession supplied and get feature info
foreach my $acc(@Accs){
  foreach my $feature (keys %{$ClusterFeatures{$acc}}){
    my $gene = $FeatureInfo{$feature}{'gene'};
    my $score = $FeatureInfo{$feature}{'score'};
    print "$acc\t$gene\t$feature\t$score\n";
  }
}
