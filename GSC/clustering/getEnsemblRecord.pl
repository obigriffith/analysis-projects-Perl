#!/usr/local/bin/perl56

use DBI;
use strict;
use Data::Dumper;

use lib "/home/obig/lib/ensembl_32_perl_API/ensembl/modules";
use lib "/home/obig/lib/ensembl_32_perl_API/ensembl-external/modules";

use Bio::EnsEMBL::DBSQL::DBAdaptor;

my $user = 'ensembl';
my $password = 'ensembl';
my $host = 'db02';#my $host = 'db01';
#my $dbname = "homo_sapiens_core_30_35c";
my $dbname = "homo_sapiens_core_32_35e";
#my $dbname = "drosophila_melanogaster_core_32_4";
#my $dbname = "drosophila_melanogaster_core_31_3e";
#my $dbname = "drosophila_melanogaster_core_33_4";

#my $db = new Bio::EnsEMBL::DBSQL::DBAdaptor(-host => $host,
#					    -user => $user,
#					    -dbname => $dbname,
#					    -pass => $password);

my $db = new Bio::EnsEMBL::DBSQL::DBAdaptor(-host => 'kaka.sanger.ac.uk',
					    -user => 'anonymous',
					    -dbname => $dbname);


my $gene_adaptor = $db->get_GeneAdaptor;
#my $gene = $gene_adaptor->fetch_by_stable_id('CG3796');
my $gene = $gene_adaptor->fetch_by_stable_id('ENSG00000107949');
#print Dumper ($gene);

my @DBlinks = @{$gene->get_all_DBLinks()};

my $external_name = $gene->external_name(); #For Homo sapiens this gets a HUGO ID
foreach my $link (@{$gene->get_all_DBLinks}) {
#foreach my $link (@{$gene->get_all_DBEntries()}){
  my $link_database = $link->database;
  my $link_id = $link->display_id;
  print "\t\t$link\t$link_database\t$link_id\n";
}


#print Dumper (@DBlinks);
#print "\nExt name: $external_name\n";

exit;
