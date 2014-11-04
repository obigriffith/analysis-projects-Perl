#!/usr/local/bin/perl56 -w
#First connect to ensembl database with ensembl API
use DBI;
use strict;
use lib "/home/obig/lib/ensembl/modules";
use lib "/home/obig/lib/ensembl-external/modules";
use lib "/home/obig/lib";
use Bio::EnsEMBL::DBSQL::DBAdaptor;

use Bio::SeqIO;
use Data::Dumper;
use Getopt::Std;
my $dbname = 'caenorhabditis_elegans_core_19_116';
my $user = 'ensembl';
my $password = 'ensembl';
my $host = 'db02';
my $db = new Bio::EnsEMBL::DBSQL::DBAdaptor(-host => $host,
					    -user => $user,
					    -dbname => $dbname,
					    -pass => $password);


my @ext_ids = ('AH6.5','B0222.6','B0222.7');
#my @ext_ids;
#while(<INFILE>){
#  if ($_=~/^(\S+)\t.*/){
#    my $ext_id = $1;
#     push (@ext_ids, $ext_id);
#  }
#}


foreach my $ext_id(@ext_ids){
  my $gene_adaptor = $db->get_GeneAdaptor;

  #Get all possible genes associated with the ID given.  One of these will be the one we are looking
  #for.  This would not be necessary id there was some way to specify the type of ext_id we are supplying
  #In the latest API (for ens19) the following new function might work: $geneAdaptor->fetch_by_maximum_DBLink($ext_id)
  my @genes = @{$gene_adaptor->fetch_all_by_DBEntry($ext_id)};
  #my $gene = $gene_adaptor->fetch_by_maximum_DBLink($ext_id);
  unless(@genes){
    print "No Ensembl gene found for $ext_id\n";
    next;
  }
  foreach my $gene (@genes) {
    # Get external descriptive information if a gene is known and see if any LocusLink data is available
    # If the LocusLink ID is the one we are looking for then the associated stable ID will be correct
    # print Dumper ($gene);
    my $gene_stable_id = $gene->stable_id;
    my $gene_name = $gene->external_name;
    print "Stable ID: $gene_stable_id\tgene_name: $gene_name\n";
  }
}



