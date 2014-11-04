#!/usr/local/bin/perl56 -w

use DBI;
use strict;
use lib "/home/obig/lib/ensembl/modules";
use lib "/home/obig/lib/ensembl-external/modules";
use lib "/home/obig/lib";
use Bio::EnsEMBL::DBSQL::DBAdaptor;
use Bio::EnsEMBL::Lite::DBAdaptor;
use Bio::EnsEMBL::ExternalData::ESTSQL::DBAdaptor;
use Bio::SeqIO;
use Data::Dumper;

#my $user = 'ensembl';
#my $password = 'ensembl';
#my $host = 'db01';
my $host = 'kaka.sanger.ac.uk';
my $user = 'anonymous';
my $dbname = 'homo_sapiens_core_16_33';
my $db = new Bio::EnsEMBL::DBSQL::DBAdaptor(-host => $host,
					    -user => $user,
					    -dbname => $dbname);
#					    -pass => $password);

my $infile = "/home/pubseq/BioSw/Cluster/Algorithm-Cluster-1.22/data/human.clean3";
my $outfile = "/home/pubseq/BioSw/Cluster/Algorithm-Cluster-1.22/data/human_locus_ens_gene_map_kaka.txt";
#Create a second file with just one gene name per Locus Link.  A Locus link can have several ENS
#gene Ids but should only have one gene name (I think).
my $outfile2 = "/home/pubseq/BioSw/Cluster/Algorithm-Cluster-1.22/data/human_locus_gene_map_kaka.txt";

open (INFILE, $infile);
#@ext_ids = (1,10,100,1000,10000,10001);
my @ext_ids;
while(<INFILE>){
  if ($_=~/^(\d+)\t.*/){
    my $locus_link = $1;
    push (@ext_ids, $locus_link);
  }
}
close INFILE;

open (OUTFILE, ">$outfile");
my %genes;
foreach my $ext_id(@ext_ids){
  my $gene_adaptor = $db->get_GeneAdaptor;

  #Get all possible genes associated with the ID given.  One of these will be the one we are looking
  #for.  This would not be necessary id there was some way to specify the type of ext_id we are supplying
  my @genes = @{$gene_adaptor->fetch_all_by_DBEntry($ext_id)};

  # Get external descriptive information if a gene is known and see if any LocusLink data is available
  # If the LocusLink ID is the one we are looking for then the associated stable ID will be correct
  foreach my $gene (@genes) {
#    print Dumper ($gene);
    my $gene_stable_id = $gene->stable_id;
    my $gene_name = $gene->external_name;
    if ($gene->is_known) {
      foreach my $link (@{$gene->get_all_DBLinks}) {
	my $link_database = $link->database;
	my $link_id = $link->display_id;
	if ($link_database eq 'LocusLink' && $link_id eq $ext_id){
	  print "$ext_id\t$gene_stable_id\t$gene_name\n";
	  print OUTFILE "$ext_id\t$gene_stable_id\t$gene_name\n";
	  $genes{$ext_id}=$gene_name;
	}
      }
    } else {
      print "Gene " . $gene->stable_id . " is not a known gene\n";
    }
  }
  #foreach locus link id.  If nothing is found above, enter a value n/a or something
  unless ($genes{$ext_id}){
    print "No LocusLink entry found in $dbname for LocusLink: $ext_id\n";
    $genes{$ext_id} = 'n/a';
  }
}
close OUTFILE;

open (OUTFILE2, ">$outfile2");
foreach my $locus(sort keys %genes){
  print OUTFILE2 "$locus\t$genes{$locus}\n";
}
close OUTFILE2;
exit;

#Other things tried
#The following seems to get the correct stable ID but also returns incorrect ones in array.
#my @genes = @{$gene_adaptor->fetch_all_by_DBEntry($ext_id)};
#foreach my $gene (@genes) {
#  print "Gene : " . $gene->stable_id . "\n";
#}

#The following returns the largest stable ID that it can find with the $ext_id.  Usually correct but not always
#my $gene = $gene_adaptor->fetch_by_maximum_DBLink($ext_id);
#print "EnsEMBL gene stable id: " . $gene->stable_id . "\n";

#The following produces all synonyms for gene
#	my @syns = @{$link->get_all_synonyms};
#	print "Synonyms for gene are @syns\n" if scalar @syns > 0;

#The following produces the gene description
#    my $description = $gene->description;
#    print "Gene description is $description\n";
