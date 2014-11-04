#!/usr/bin/perl -w
#!/opt/csw/bin/perl -w
#!/usr/local/bin/perl56 -w
#!/usr/local/bin/perl -w

use DBI;
use strict;
use Data::Dumper;
use Getopt::Std;
use lib "/home/obig/lib";
use lib "/home/obig/lib/ensembl_30_perl_API/ensembl/modules";
use Bio::EnsEMBL::DBSQL::DBAdaptor;
#use Bio::SeqIO;

my $user = 'ensembl';
my $password = 'ensembl';
my $host = 'db02';
my $dbname = 'homo_sapiens_core_30_35c';
my $db = new Bio::EnsEMBL::DBSQL::DBAdaptor(-host => $host,
					    -user => $user,
					    -dbname => $dbname,
					    -pass => $password);
my %EntrezHugo;
my %gene_mapping;
my $gene_count=0;
my $known_gene_count=0;
my $hugo_count=0;
my $entrez_count=0;
my $outfile = "ALL_ENSG_2_HUGO_Symbol_and_EntrezGene_ENS30_35c";
my $HUGO_mapfile = "HUGO_Symbol_2_EntrezGene_from_HGNC";

open (OUTFILE, ">$outfile") or die "can't open $outfile\n";

open (HUGO, $HUGO_mapfile) or die "can't open $HUGO_mapfile\n";
while (<HUGO>){
  if ($_=~/(\S+)\s+(\S+)/){
    $EntrezHugo{$2}=$1;
  }
}
close HUGO;

#Get all gene ids from Ensembl API
my $gene_adaptor = $db->get_GeneAdaptor;
my @stable_gene_ids = @{$gene_adaptor->list_stable_ids()};

foreach my $stable_gene_id (@stable_gene_ids) {
  $gene_count++;
  my $gene = $gene_adaptor->fetch_by_stable_id($stable_gene_id);
  my $gene_name = $gene->external_name;
  #print Dumper ($gene);
  print "$stable_gene_id\n";
  
  if ($gene->is_known) {
    $known_gene_count++;
    foreach my $link (@{$gene->get_all_DBLinks}) {
      my $link_database = $link->database;
      my $link_id = $link->display_id;
      #print "$link_database\t$link_id\n";
      #print "comparing $link_database to $ext_id_type and $link_id to $ext_id\n";
      if ($link_database eq 'HUGO'){
	#print "$link_id\t";
	$gene_mapping{$stable_gene_id}{'HUGO'}=$link_id;
      }
      if ($link_database eq 'EntrezGene'){
	#print "$link_id";
	$gene_mapping{$stable_gene_id}{'EntrezGene'}=$link_id;
      }
    }
  }else {
    #print "Gene " . $gene->stable_id . " is not a known gene\n";
  }
}

foreach my $gene (sort keys %gene_mapping){
  my $hugo="";
  my $entrez="";
  #First check for HUGO ID
  if ($gene_mapping{$gene}{'HUGO'}){
    $hugo_count++;
    $hugo = $gene_mapping{$gene}{'HUGO'};
  }
  if ($gene_mapping{$gene}{'EntrezGene'}){ #If no HUGO but EntrezGene present, checking HUGO mapping file
    $entrez_count++;
    $entrez = $gene_mapping{$gene}{'EntrezGene'};
    if ($EntrezHugo{$entrez}){
      $hugo = $EntrezHugo{$entrez};
    }
  }
  print OUTFILE "$gene\t$hugo\t$entrez\n";
}

print "Summary:
$gene_count genes
$known_gene_count known genes
$hugo_count with HUGO ID
$entrez_count with Entrez\n";

close OUTFILE;
exit;

