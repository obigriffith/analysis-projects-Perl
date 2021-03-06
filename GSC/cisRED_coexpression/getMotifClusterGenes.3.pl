#!/usr/bin/perl -w
#!/usr/local/bin/perl -w

use DBI;
use strict;

$| = 1;

#-----DATABASE CONNECTION-----------------
my $server = "db01";
my $user_name = "viewer";
my $password = "viewer";

my $db_name = "cisred_1_2e";

my $dsn = "DBI:mysql:$db_name:$server";
#------------------------------------------

my $dbh = DBI->connect($dsn,$user_name,$password,{PrintError=>1}) || die;

#Global variables
my %FeatureInfo;
my %MotifClusters;
my %ClusterFeatures;
my %GeneClusters;

# get all features and their corresponding Ensembl IDs
#print "Getting features from $db_name:$server\n";
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
#my $sth2 = $dbh->prepare( "SELECT accession_id, feature_id FROM accession;" ) || die "error in pop table";
#As of cisred_1_2e the accession table was changed to group_content.  Records with group_id of 0 or -1 should be ignored
my $sth2 = $dbh->prepare( "SELECT group_id, feature_id FROM group_content where group_id>0;" ) || die "error in pop table";
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

#From feature clusters, determine gene clusters (Two features in the same motif cluster can represent a single gene)
#print "Determining gene clusters\n";
foreach my $cluster_id (sort keys %ClusterFeatures){
  my $motif_cluster_size=$MotifClusters{$cluster_id};
  if ($motif_cluster_size>1){ #Don't care about clusters of size 1
    foreach my $feature_id (sort{$a<=>$b} keys %{$ClusterFeatures{$cluster_id}}){
      my $gene_id=$FeatureInfo{$feature_id}{'gene'};
      my $sequence=$FeatureInfo{$feature_id}{'sequence'};
      my $consensus=$FeatureInfo{$feature_id}{'consensus'};
      my $score=$FeatureInfo{$feature_id}{'score'};
      $GeneClusters{$cluster_id}{$gene_id}{$feature_id}{'score'}=$score;
#      print "$cluster_id\t$feature_id\t$gene_id\t$sequence\t$consensus\t$score\t$motif_cluster_size\n";
    }
  }
}

#print "$cluster_id\t$gene_cluster_size\t$motif_cluster_size\t$average_motif_score\t",join(" ",@cluster_genes),"\n";
#Foreach gene cluster calculate simple stats
foreach my $cluster_id (sort keys %GeneClusters){
  my $gene_cluster_size=0;
  my @cluster_genes;
  my $total_score=0;
  my $motif_cluster_size=$MotifClusters{$cluster_id};
  foreach my $gene_id (sort keys %{$GeneClusters{$cluster_id}}){
    $gene_cluster_size++;
    push (@cluster_genes, $gene_id);
    foreach my $feature (keys %{$GeneClusters{$cluster_id}{$gene_id}}){
      $total_score+=$GeneClusters{$cluster_id}{$gene_id}{$feature}{'score'};
    }
  }
  my $average_motif_score=$total_score/$motif_cluster_size;
  if ($gene_cluster_size>1){
    print "$cluster_id\t$gene_cluster_size\t$motif_cluster_size\t$average_motif_score\t",join(" ",@cluster_genes),"\n";
  }
}

exit;

