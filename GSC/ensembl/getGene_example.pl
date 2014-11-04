#!/usr/bin/perl -w
#!/opt/csw/bin/perl -w
#!/usr/local/bin/perl56 -w
#!/usr/local/bin/perl -w

use DBI;
use strict;
use Data::Dumper;
use Getopt::Std;
use lib "/home/obig/lib";
use lib "/home/obig/lib/ensembl_43_perl_API/ensembl/modules";
use Bio::EnsEMBL::DBSQL::DBAdaptor;
#use Bio::SeqIO;

#my $user = 'ensembl';
#my $password = 'ensembl';
my $user = 'anonymous';
#my $host = 'db02';
#my $host = 'db01';
my $host = "ensembldb.ensembl.org";
#my $dbname = 'homo_sapiens_core_43_36e';
my $dbname = 'mus_musculus_core_43_36d';
my $db = new Bio::EnsEMBL::DBSQL::DBAdaptor(-host => $host,
					    -user => $user,
#					    -pass => $password,
					    -dbname => $dbname);


getopts("i:t:");
use vars qw($opt_i $opt_t);

#user documentation
unless ($opt_i && $opt_t){&printDocs();}

my $ext_id = $opt_i;
my $ext_id_type = $opt_t;


my (%genes, %genes_rev);

my $gene_adaptor = $db->get_GeneAdaptor;
my @genes = @{$gene_adaptor->fetch_all_by_external_name($ext_id)};

  foreach my $gene (@genes) {
    #Get external descriptive information if a gene is known
    #If the ID is the one we are looking for then the associated stable ID will be correct
    #print Dumper ($gene);
    my $gene_stable_id = $gene->stable_id;
    #print "Stable ID: $gene_stable_id\n";
    my $gene_name = $gene->external_name;
    if ($gene->is_known) {
      foreach my $link (@{$gene->get_all_DBLinks}) {
	my $link_database = $link->database;
	my $link_id = $link->display_id;
	print "$link_database\t$link_id\n";
	#print "comparing $link_database to $ext_id_type and $link_id to $ext_id\n";
	if ($link_database eq $ext_id_type && $link_id eq $ext_id){
	  print "\next_ID\tEnsembl_stable_ID\tgene_name\n";
	  print "$ext_id\t$gene_stable_id\t$gene_name\n";
	  $genes{$ext_id}{$gene_stable_id}=$gene_name;
	  $genes_rev{$gene_stable_id}{$ext_id}=$gene_name;
	  last;
	}
      }
    } else {
      print "Gene " . $gene->stable_id . " is not a known gene\n";
    }
  }
exit;

sub printDocs{
print "Supply following options:\n";
print "-i ID (eg. BIRC5)\n";
print "-t ID type (eg. HUGO)\n\n";
print "possible ID types to lookup Ensembl Ids for:
Human:
LocusLink
RefSeq
SWISSPROT
EMBL
SPTREMBL
protein_id
MarkerSymbol
GO
MIM
Uniprot/SWISSPROT
Uniprot/SPTREMBL
UMCU_Hsapiens_19Kv1
HUGO
PDB
AFFY_HG_U133_PLUS_2
AFFY_HG_U133A
AFFY_HG_Focus
AFFY_HG_U133A_2
AFFY_HG_U95Av2
AFFY_U133_X3P

Mouse:
Illumina
AFFY_Mouse430_2
AFFY_MOE430B
AFFY_Mu11KsubB
AFFY_MG_U74Av2
AFFY_MG_U74A
AFFY_Mouse430_2
AFFY_Mouse430A_2
AFFY_MOE430A
RefSeq_dna
UniGene
UniGene
AgilentProbe
AgilentProbe
Illumina_V1
Codelink
Codelink
CCDS
EntrezGene
";
exit;
}
