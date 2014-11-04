#!/usr/bin/perl -w
#!/usr/local/bin/perl56 -w
#!/usr/local/bin/perl -w


use DBI;
use strict;
use Data::Dumper;
use Getopt::Std;
getopts("f:o:l:e:t:d:v:h:");
use vars qw($opt_f $opt_o $opt_l $opt_e $opt_t $opt_d $opt_v $opt_h);
if ($opt_t eq 'help'){&printIDtypes();}
unless ($opt_t && $opt_f && $opt_l && $opt_o && $opt_e && $opt_d){&printDocs();} #you must specify all these options
#Allow option for older API versions if necessary
my $version=$opt_v;
#default to latest version, update periodically
my $bioperl_lib = "/home/obig/lib";
my $ensembl_lib="/home/obig/lib/ensembl_21_perl_API/ensembl/modules";
my $ensembl_external_lib="/home/obig/lib/ensembl_21_perl_API/ensembl-external/modules";
if ($version eq '16'){$ensembl_lib="/home/obig/lib/ensembl_16_perl_API/ensembl/modules";$ensembl_external_lib="/home/obig/lib/ensembl_16_perl_API/ensembl-external/modules";}
if ($version eq '17'){$ensembl_lib="/home/obig/lib/ensembl_17_perl_API/ensembl/modules";$ensembl_external_lib="/home/obig/lib/ensembl_17_perl_API/ensembl-external/modules";}
if ($version eq '18'){$ensembl_lib="/home/obig/lib/ensembl_18_perl_API/ensembl/modules";$ensembl_external_lib="/home/obig/lib/ensembl_18_perl_API/ensembl-external/modules";}
if ($version eq '19'){$ensembl_lib="/home/obig/lib/ensembl_19_perl_API/ensembl/modules";$ensembl_external_lib="/home/obig/lib/ensembl_19_perl_API/ensembl-external/modules";}
if ($version eq '20'){$ensembl_lib="/home/obig/lib/ensembl_20_perl_API/ensembl/modules";$ensembl_external_lib="/home/obig/lib/ensembl_20_perl_API/ensembl-external/modules";}
if ($version eq '21'){$ensembl_lib="/home/obig/lib/ensembl_21_perl_API/ensembl/modules";$ensembl_external_lib="/home/obig/lib/ensembl_21_perl_API/ensembl-external/modules";}
if ($version eq '22'){$ensembl_lib="/home/obig/lib/ensembl_22_perl_API/ensembl/modules";$ensembl_external_lib="/home/obig/lib/ensembl_22_perl_API/ensembl-external/modules";}
if ($version eq '27'){$ensembl_lib="/home/obig/lib/ensembl_27_perl_API/ensembl/modules";$ensembl_external_lib="/home/obig/lib/ensembl_27_perl_API/ensembl-external/modules";}
if ($version eq '28'){$ensembl_lib="/home/obig/lib/ensembl_28_perl_API/ensembl/modules";$ensembl_external_lib="/home/obig/lib/ensembl_28_perl_API/ensembl-external/modules";}
if ($version eq '29'){$ensembl_lib="/home/obig/lib/ensembl_29_perl_API/ensembl/modules";$ensembl_external_lib="/home/obig/lib/ensembl_29_perl_API/ensembl-external/modules";}
if ($version eq '30'){$ensembl_lib="/home/obig/lib/ensembl_30_perl_API/ensembl/modules";$ensembl_external_lib="/home/obig/lib/ensembl_30_perl_API/ensembl-external/modules";}
if ($version eq '31'){$ensembl_lib="/home/obig/lib/ensembl_31_perl_API/ensembl/modules";$ensembl_external_lib="/home/obig/lib/ensembl_31_perl_API/ensembl-external/modules";}

#First connect to ensembl database with ensembl API
use lib "/home/obig/lib";
#edit @INC to use correct path.  then require instead of use Bio::EnsEMBL::DBSQL::DBAdaptor;  Then you may have to supply full path when actually calling functions Bio::blah::getDBadaptor.
push (@INC, $ensembl_lib);
push (@INC, $ensembl_external_lib);
#push (@INC, $bioperl_lib);

require Bio::EnsEMBL::DBSQL::DBAdaptor;
require Bio::SeqIO;


#Supply type of ID to look for in ensembl (eg. LocusLink, wormbase_gene, flybase_gene, HUGO, etc)
my $ext_id_type = $opt_t;
#Supply genes to map to ensembl IDs in file
my $infile = $opt_f;
my $outfile = $opt_l;
#Create a second file with just one gene name per Locus Link.  A Locus link can have several ENS
#gene Ids but should only have one gene name (I think).
my $outfile2 = $opt_o;
my $errorfile = $opt_e;
my $dbname = $opt_d;
my $host = $opt_h;

#database connection parameters
#For testing or to use web: my $host = 'kaka.sanger.ac.uk'; #my $user = 'anonymous';
my $user = 'ensembl';
my $password = 'ensembl';
my $db = new Bio::EnsEMBL::DBSQL::DBAdaptor(-host => $host,
					    -user => $user,
					    -dbname => $dbname,
					    -pass => $password);


#global variables
my (%genes, %genes_rev);

#Get list of Ids to look up in ensembl
open (INFILE, $infile);
my @ext_ids;
my $count = 0;
while(<INFILE>){
#  if ($_=~/^(\d+)/){
  if ($_=~/^(\S+)\s+.*/){
    $count++;
    my $ext_id = $1;
    ########Data type specific regexps to deal with format inconsistencies###################
    if ($ext_id=~m/^FBGN/i){$ext_id=~s/FBGN/FBgn/;} #for drosophila data, make flybase friendly
    if ($ext_id=~m/^AT\dG/i){$ext_id=~tr/aTG/Atg/;} #For TIGR/AGI Ids which ensembl has in the form: At2g26460
   ##############################################################################################
    push (@ext_ids, $ext_id);
    print "IDs to check in ensembl: $count\r";
  }
}
close INFILE;

#my @ext_ids = (70465, 50493, 16172);
#my @ext_ids = ('99985_at','99991_at','92432_at');
#@ext_ids = ('ENSMUSG00000000561','ENSMUSG00000004929','ENSMUSG00000025579','ENSMUSG00000024590');



print "\n\nSearching Ensembl for genes\n";
open (ERR, ">$errorfile");
open (OUTFILE, ">$outfile");

#If ensembl ID is provided, the functions below won't work because Ensembl is not an external ID
if ($ext_id_type eq 'Ensembl'){
  &checkEnsemblforEnsemblID();
  exit;
}

foreach my $ext_id(@ext_ids){
  my $gene_adaptor = $db->get_GeneAdaptor;
  #print Dumper($gene_adaptor);
  #Get all possible genes associated with the ID given.  One of these will be the one we are looking
  #for.  This would not be necessary if there was some way to specify the type of ext_id we are supplying
  my @genes;
  if ($version<20){
    @genes = @{$gene_adaptor->fetch_all_by_DBEntry($ext_id)};
  }else{
    @genes = @{$gene_adaptor->fetch_all_by_external_name($ext_id)};#fetch_all_by_DBEntry deprecated
  }
  unless(@genes){
    print "No Ensembl gene found for $ext_id\n";
    print ERR "No Ensembl gene:\t$ext_id\n";
    $genes{$ext_id}{'n/a'} = 'n/a';
    $genes_rev{'n/a'}{$ext_id} = 'n/a';
    next;
  }
  foreach my $gene (@genes) {
    #Get external descriptive information if a gene is known and see if any LocusLink data is available
    #If the LocusLink ID is the one we are looking for then the associated stable ID will be correct
    #print Dumper ($gene);
    my $gene_stable_id = $gene->stable_id;
    #print "Stable ID: $gene_stable_id\n";
    my $gene_name = $gene->external_name;
    if ($gene->is_known) {
      foreach my $link (@{$gene->get_all_DBLinks}) {
	my $link_database = $link->database;
	my $link_id = $link->display_id;
	print "\t\t$link\t$link_database\t$link_id\n";
	#print "comparing $link_database to $ext_id_type and $link_id to $ext_id\n";
	if ($link_database eq $ext_id_type && $link_id eq $ext_id){
	  print "$ext_id\t$gene_stable_id\t$gene_name\n";
	  print OUTFILE "$ext_id\t$gene_stable_id\t$gene_name\n";
	  $genes{$ext_id}{$gene_stable_id}=$gene_name;
	  $genes_rev{$gene_stable_id}{$ext_id}=$gene_name;
	  last;
	}
      }
    } else {
      print "Gene " . $gene->stable_id . " is not a known gene\n";
    }
  }
  #foreach locus link id.  If nothing is found above, enter a value n/a or something
  unless ($genes{$ext_id}){
    print "No entry found in $dbname for $ext_id\n";
    print ERR "No entry:\t$ext_id\n";
    $genes{$ext_id}{'n/a'} = 'n/a';
    $genes_rev{'n/a'}{$ext_id} = 'n/a';
  }
}
close OUTFILE;

open (OUTFILE2, ">$outfile2");
foreach my $ext_id (sort keys %genes){
  #There should be only one ensembl gene ID for each ext_ID.  But if there is more than one we should take note:
  my $matches = keys %{$genes{$ext_id}};
  if ($matches>1){
    print "multiple matches found for: $ext_id\tmatches:$matches\n";
    print ERR "multiple matches found ($matches):\t$ext_id\n";
    print OUTFILE2 "$ext_id\tn/a\tn/a\n";
    next;
  }
  foreach my $ens_id(sort keys %{$genes{$ext_id}}){
    #There should not be more than one ext_ID for the same ensembl gene Id.
    my $duplicates = keys %{$genes_rev{$ens_id}};
    if ($duplicates>1){
      if ($ens_id eq 'n/a'){ #Don't consider all genes with n/a for ensembl ID as duplicates
	print OUTFILE2 "$ext_id\tn/a\tn/a\n";	
	next;
      }
      print "duplicate matches found for: $ext_id\tduplicates:$duplicates\n";
      print ERR "duplicate matches found ($duplicates):\t$ext_id\n";
      print OUTFILE2 "$ext_id\tn/a\tn/a\n";
      next;
    }else{
      print OUTFILE2 "$ext_id\t$ens_id\t$genes{$ext_id}{$ens_id}\n";
    }
  }
}
close OUTFILE2;
close ERR;
exit;


sub printDocs{
print "you must specify the following options:\n";
print "-d   database (eg. caenorhabditis_elegans_core_19_102, homo_sapiens_core_19_34a, drosophila_melanogaster_core_19_3a, arabidopsis_thaliana_core_16_TIGR4, etc)\n";
print "-h   host (eg. db01)\n";
print "-v   version of ensembl API to use.  Defaults to most current but also allows v.16 to be specified if needed\n";
print "-t   type of ID (eg. LocusLink, wormbase_gene, flybase_gene, HUGO, TIGR, AFFY_MG_U74Av2, etc (use 'getGeneID2 -t help' to see more examples))\n";
print "-f   file containing genes to be mapped to ensembl IDs\n";
print "-l   logfile showing all mappings of these genes to ensemble IDs\n";
print "-e   error file containing all Ids with problems mapping to ensembl\n";
print "-o   output file containing only unambiguous mappings (whereas logfile will contain multiple matches in some cases\n";
exit;
}

sub printIDtypes{
print "possible ID types to lookup Ensembl Ids for:
Newer types (for versions 30 and later)
PUBMED
EMBL
protein_id
MIM
PDB
Uniprot/SWISSPROT
RefSeq_peptide
RefSeq_dna (replaces refseq)
EntrezGene (replaces LocusLink)

Older Types (for versions 27 and earlier)
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

AFFY IDS
Mouse:
AFFY_MG_U74A
AFFY_MG_U74Av2
AFFY_MOE430A
AFFY_Mu11KsubA

Human:
AFFY_HG_U133_PLUS_2
AFFY_HG_U133A
AFFY_HG_Focus
AFFY_HG_U133A_2
AFFY_HG_U95Av2
AFFY_U133_X3P
";
exit;
}


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

#The following was partially developed to look up Ensembl Ids by Ensembl ID.
#sub checkEnsemblforEnsemblID{
#  my @genes;
#  my $gene_adaptor = $db->get_GeneAdaptor;
#  my @stable_gene_ids = @{$gene_adaptor->list_stable_ids()};
#  foreach my $ext_id(@ext_ids){
#    foreach my $stable_id(@stable_gene_ids){
#      if ($ext_id eq $stable_id){
#	print "$ext_id found\n";
#      }
#    }
#  }
#  return();
#}
