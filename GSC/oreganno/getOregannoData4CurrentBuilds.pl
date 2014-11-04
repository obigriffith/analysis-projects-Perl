#!/usr/bin/perl

use strict;
use DBI;
use Data::Dumper;
use Getopt::Std;

getopts("o:t:");
use vars qw($opt_t $opt_o);

my $server = "web02";
my $user_name = "oregano";
my $password = "IFjwqee";
my $db_name = "oregano";

my $dbh = DBI->connect("DBI:mysql:$db_name:$server",$user_name,$password) or die "Couldn't connect to database: " . DBI->errstr;

my $SQL_GET_RECORD = "SELECT * FROM record WHERE type != 'REGULATORY HAPLOTYPE' AND deprecated_by_record IS NULL ORDER BY species_id, stable_id";

my $sth_rec = $dbh->prepare($SQL_GET_RECORD) or die "Couldn't prepare statement: " . $dbh->errstr;

$sth_rec -> execute() or die "Couldn't execute statement: " . $sth_rec -> errstr;

unless($opt_t && $opt_o){print "\nusage:tab-delim.pl -o outfile.txt -t filetype [UCSC/FULL]\n\n"; exit;}
my $file_type = $opt_t; #SET TYPE VARIABLE HERE FOR 'UCSC' FILE OR 'FULL' DATA FILE;
my $outfile = $opt_o;

open(OUTFILE, ">$outfile");

if ($file_type eq 'UCSC'){
print OUTFILE "Species\tUCSC Build\tMapping status\tOutcome\tchrom\tchromStart\tchromEnd\tStrand\tname\tlandMarkId\tlandMarkType\tGene name\tGene ID\tGene Source\tTF name\tTF ID\tTF Source\tdbSNP ID\tPMID\tDataset\tEvidence Subtypes\n";
}
if ($file_type eq 'FULL'){
print OUTFILE "Species\tUCSC Build\tBuild\tMapping status\tOutcome\tchrom\tchromStart\tchromEnd\tStrand\tStable Id\tType\tGene name\tGene ID\tGene Source\tTF name\tTF ID\tTF Source\tdbSNP ID\tPMID\tDataset\tEvidence Subtypes\tRegulatory Sequence\tRegulatory Sequence With Flank\tSequence Search Space\tPolymorphism Reference Sequence\tPolymorphism Variant Sequence\n";
}

while (my $row_ref = $sth_rec -> fetchrow_arrayref()) {
	my $record_id = @{$row_ref}[0];
	my $stable_id = @{$row_ref}[1];
	my $outcome = @{$row_ref}[2];
	my $dataset_id = @{$row_ref}[3];
	my $gene_source = @{$row_ref}[4];
	my $gene_id = @{$row_ref}[5];
	my $gene_name = @{$row_ref}[6];
	my $gene_version = @{$row_ref}[7];
	my $tf_source = @{$row_ref}[8];
	my $tf_id = @{$row_ref}[9];
	my $tf_name = @{$row_ref}[10];
	my $tf_version = @{$row_ref}[11];
	my $loci_name = @{$row_ref}[12];
	my $regulatory_sequence = @{$row_ref}[13];
	my $regulatory_sequence_with_flank = @{$row_ref}[14];
	my $sequence_search_space = @{$row_ref}[15];
	my $species_id = @{$row_ref}[16];
	my $old_pubmed_id = @{$row_ref}[17]; #Note: When queue was added to oreganno, pubmed ids were moved to a separate table called "reference"
	my $reference_id = @{$row_ref}[18];
	my $entry_date = @{$row_ref}[19];
	my $type = @{$row_ref}[20];
	my $deprecated_by_record = @{$row_ref}[21];
	my $deprecated_by_user = @{$row_ref}[22];
	my $deprecated_by_date = @{$row_ref}[23];
	my $user_id = @{$row_ref}[24];
	#Deal with empty values
	unless ($tf_source){$tf_source='N/A';}
	unless ($gene_source){$gene_source='N/A';}
	unless($regulatory_sequence){$regulatory_sequence='N/A';}
	unless($regulatory_sequence_with_flank){$regulatory_sequence_with_flank='N/A';}
	unless($sequence_search_space){$sequence_search_space='N/A';}

	#Get Pubmed ID from reference ID
	my $SQL_GET_PMID = "SELECT pubmed_id FROM reference where reference.id=\"$reference_id\"";
	my $sth_pmid = $dbh->prepare($SQL_GET_PMID) or die "Couldn't prepare statement: " . $dbh->errstr;
	$sth_pmid -> execute() or die "Couldn't execute statement: " . $sth_pmid -> errstr;
	$row_ref = $sth_pmid -> fetchrow_arrayref();
	my $pubmed_id = @{$row_ref}[0];
	$sth_pmid -> finish;

	#Get species name for species_id
	my $SQL_GET_SPECIES = "SELECT species_name FROM species WHERE species.id=\"$species_id\"";
	my $sth_spec = $dbh->prepare($SQL_GET_SPECIES) or die "Couldn't prepare statement: " . $dbh->errstr;
	$sth_spec -> execute() or die "Couldn't execute statement: " . $sth_spec -> errstr;
	$row_ref = $sth_spec -> fetchrow_arrayref();
	my $species = @{$row_ref}[0];
	$sth_spec -> finish;

	#Get mapping information for most recent mapping
	my $SQL_GET_MAPPING;
	if ($file_type eq 'UCSC'){
	  $SQL_GET_MAPPING = "SELECT mapping.*, ucsc_build_name FROM mapping, mapping_genome WHERE mapping.record_id=\"$record_id\" AND mapping.mapping_genome_id=mapping_genome.id AND ucsc_build_name IS NOT NULL ORDER BY mapping_genome_id DESC";
	}
	if ($file_type eq 'FULL'){
	  $SQL_GET_MAPPING = "SELECT mapping.*, ucsc_build_name, build_name FROM mapping, mapping_genome WHERE mapping.record_id=\"$record_id\" AND mapping.mapping_genome_id=mapping_genome.id ORDER BY mapping_genome_id DESC";
	}
	my $sth_map = $dbh->prepare($SQL_GET_MAPPING) or die "Couldn't prepare statement: " . $dbh->errstr;
	$sth_map -> execute() or die "Couldn't execute statement: " . $sth_map -> errstr;
	my $row_ref = $sth_map -> fetchrow_arrayref();
	my $sequence_region_name = @{$row_ref}[3];
	my $start = @{$row_ref}[4];
	my $end = @{$row_ref}[5];
	my $strand = @{$row_ref}[6];
	my $mapping_status = @{$row_ref}[10];
	my $ucsc_build = @{$row_ref}[11];
	my $build = @{$row_ref}[12];
 	$sth_map -> finish;

	#Get variation details for regulatory polymorphisms
	my $SQL_GET_VARIATION = "SELECT * FROM variation WHERE record_id=\"$record_id\"";
	my $sth_var = $dbh->prepare($SQL_GET_VARIATION) or die "Couldn't prepare statement: " . $dbh->errstr;
        $sth_var -> execute() or die "Couldn't execute statement: " . $sth_var -> errstr;
        my $row_ref = $sth_var -> fetchrow_arrayref();
	my $reference_sequence = @{$row_ref}[2];
	my $variant_sequence = @{$row_ref}[3];
	my $regulatory_variation_cross_reference = @{$row_ref}[6];
	$sth_var -> finish;
	unless($reference_sequence){$reference_sequence='N/A';}
	unless($variant_sequence){$variant_sequence='N/A';}

	#Get DBSNP IDs for regulatory polymorphisms
	my $SQL_GET_VARIATION_CROSSREF = "SELECT * from regulatory_variation_cross_reference WHERE id=\"$regulatory_variation_cross_reference\" AND source=\"dbSNP\"";
	my $sth_crossref = $dbh->prepare($SQL_GET_VARIATION_CROSSREF) or die "Couldn't prepare statement: " . $dbh->errstr;
	$sth_crossref -> execute() or die "Couldn't execute statement: " . $sth_crossref -> errstr;
        my $row_ref = $sth_crossref -> fetchrow_arrayref();
	my $db_snp_id = @{$row_ref}[2];
	$sth_crossref -> finish;
	unless($db_snp_id){$db_snp_id='N/A';}

	#Get Evidence details
	my $SQL_GET_EVIDENCE = "SELECT record_evidence.*, evidence_subtype.name FROM record_evidence, evidence_subtype WHERE record_id=\"$record_id\" AND evidence_subtype.id=record_evidence.evidence_subtype_id";
	my $sth_ev = $dbh->prepare($SQL_GET_EVIDENCE) or die "Couldn't prepare statement: " . $dbh->errstr;
	$sth_ev -> execute() or die "Couldn't execute statement: " . $sth_ev -> errstr;
	my %evidence_subtypes;
	while (my $row_ref = $sth_ev -> fetchrow_arrayref()) {
		my $key = @{$row_ref}[9];
		$evidence_subtypes{$key} = '1';
	}
	$sth_ev -> finish;
	
	#Get Dataset details
	my $SQL_GET_DATASET = "SELECT name FROM dataset WHERE id=\"$dataset_id\"";
	my $sth_data = $dbh->prepare($SQL_GET_DATASET) or die "Couldn't prepare statement: " . $dbh->errstr;
	$sth_data -> execute() or die "Couldn't execute statement: " . $sth_data -> errstr;
	my $row_ref = $sth_data -> fetchrow_arrayref();
	my $dataset = @{$row_ref}[0];
	$sth_data -> finish;
	unless ($dataset) {
		$dataset = 'N/A';
	}
	
	my $i = '0';
	my $evidence_subtypes;
	foreach my $ev (sort keys %evidence_subtypes) {
		if ($i == 0) {
			$evidence_subtypes = $ev;
		} else {
			$evidence_subtypes .= "; $ev";
		}
		$i++;
	}

	if ($mapping_status eq 'NOT MAPPED') {
		$sequence_region_name = 'N/A';
		$start = 'N/A';
		$end = 'N/A';
		$strand = 'N/A';
	}
	$sequence_region_name =~ s/chr//g;


	##THIS CODE CARRIED OUT FOR MAKING UCSC FILE
	if ($file_type eq "UCSC") {
		if ($mapping_status eq "MAPPED" && $outcome eq "POSITIVE OUTCOME") {
			print OUTFILE "$species\t$ucsc_build\t$mapping_status\t$outcome\t$sequence_region_name\t$start\t$end\t$strand\t$stable_id\t$stable_id\t$type\t$gene_name\t$gene_id\t$gene_source\t$tf_name\t$tf_id\t$tf_source\t$db_snp_id\t$pubmed_id\t$dataset\t$evidence_subtypes\n";
		}
	}
	
	if ($file_type eq "FULL"){
	  print OUTFILE "$species\t$ucsc_build\t$build\t$mapping_status\t$outcome\t$sequence_region_name\t$start\t$end\t$strand\t$stable_id\t$type\t$gene_name\t$gene_id\t$gene_source\t$tf_name\t$tf_id\t$tf_source\t$db_snp_id\t$pubmed_id\t$dataset\t$evidence_subtypes\t$regulatory_sequence\t$regulatory_sequence_with_flank\t$sequence_search_space\t$reference_sequence\t$variant_sequence\n";
	}

}

$sth_rec->finish;

close OUTFILE;
$dbh->disconnect;

