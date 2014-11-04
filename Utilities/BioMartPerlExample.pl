#!/usr/bin/env genome-perl
#Written by Obi L. Griffith

#Purpose:
#This script queries the InterPro biomart website for details corresponding to an InterPro accession
#A sample perl snippet was obtained from the Biomart website and used as a starting point
#The result will be a list of UniProtKB protein accessions and other details for the provided InterPro accession

use strict;
use warnings;
use Data::Dumper;

#Note, you must have biomart-perl installed for this script to work
#This can be downloaded from: http://www.biomart.org/other/install-overview.html
#See the section title "1.2 Downloading biomart-perl" for CVS commands to run and "1.4 Installing biomart-perl" for instructions on how to install
#There were a number of dependencies missing during my installation, but the following code worked without resolving them. 
#Results may vary - ideally you will want root access or have your system admin install any missing dependencies
use lib '/gscuser/ogriffit/lib/biomart-perl/lib';

#Biomart specific libraries to call
use BioMart::Initializer;
use BioMart::Query;
use BioMart::QueryRunner;

#Note, a registry file must be provided
#This can be obtained from: http://www.biomart.org/biomart/martservice?type=registry;
#Copy this into a file and then delete all entries except those corresponding to INTERPRO and UNIPROT (or whichever database(s) you intend to query)
#This last step reduces the amount of time required to load all registries
my $confFile = "/gscuser/ogriffit/lib/biomart-perl/conf/biomart_Interpro_registry.xml"; 
my $tempfile = "biomart_query_temp.txt";

#Note regarding timeout errors
#If queries are taking too long to complete and you receive time out errors
#Find the following line: $ua->timeout(20);
#In /gscuser/ogriffit/lib/biomart-perl/lib/BioMart/Configuration/URLLocation.pm
#And increase to 180 ($ua->timeout(180);)

# Note: change action to 'clean' if you wish to start a fresh configuration  
# and to 'cached' if you want to skip configuration step on subsequent runs from the same registry
my $action='cached';
my $initializer = BioMart::Initializer->new('registryFile'=>$confFile, 'action'=>$action);
my $registry = $initializer->getRegistry;


###################################################################################################
#Query Uniprot Biomart with InterPro query term                                                            #
#For this example we will filter down to only proteins:
#In "The complete human proteome", see: http://www.uniprot.org/faq/48
#With Swiss-prot (Reviewed) status, see http://www.uniprot.org/faq/7
#With evidence at protein level, see http://www.uniprot.org/docs/pe_criteria
#We will retrieve: Uniprot Accession, Uniprot Id, Uniprot Protein Name, Uniprot Gene Name
###################################################################################################
my $queryterm="IPR000022";
print "\nAttempting UniProt list query for $queryterm\n";

my $query = BioMart::Query->new('registry'=>$registry,'virtualSchemaName'=>'default');
$query->setDataset("uniprot");
$query->addFilter("interpro_id", [$queryterm]);
$query->addFilter("proteome_name", ["Homo sapiens"]); 
$query->addFilter("entry_type", ["Swiss-Prot"]);
$query->addFilter("protein_evidence", ["1: Evidence at protein level"]);
$query->addAttribute("accession");
$query->addAttribute("name");
$query->addAttribute("protein_name");
$query->addAttribute("gene_name");
$query->addAttribute("protein_evidence");
$query->addAttribute("entry_type");
my $query_runner = BioMart::QueryRunner->new();
$query_runner->uniqueRowsOnly(1); #to obtain unique rows only

#Get count of expected results - use to make sure results are complete 
my $count_query_attempt=1;
#Turn on counting
$query->count(1); 
my $query_count;
do {
  print "Attempting query count, attempt $count_query_attempt\n";
  $query_runner->execute($query);
  $query_count=$query_runner->getCount();
  sleep(1);
  $count_query_attempt++;
} until ($query_count);

print "$query_count results expected for query\n";
#turn off counting so that full results can be obtained below
$query->count(0);

#Perform main query of interest
#Note results are directed to STDOUT by default
#Redirect and store in temporary file
my $query_attempt=1;
my $result_count;
my @results;
do {
  print "Attempting query, attempt $query_attempt\n";
  open (BIOMART_OUT, ">$tempfile") or die "Can't open $tempfile file for write\n";
  $query_runner->execute($query);
  #$query_runner->printHeader(\*BIOMART_OUT);
  $query_runner->printResults(\*BIOMART_OUT);
  #$query_runner->printFooter(\*BIOMART_OUT);
  close BIOMART_OUT;

  #Read in results and check expected results against count above
  open (BIOMART_IN, "$tempfile") or die "Can't open $tempfile\n";
  @results=<BIOMART_IN>;
  close BIOMART_IN;
  $result_count=@results;
  print "$result_count results returned for query\n\n";
  sleep(1);
  $query_attempt++;
} until ($result_count==$query_count);

#Parse results
chomp (@results);
my %UniProtDetails;
foreach my $result (@results){
  my @data=split("\t", $result);
  my $Uniprot_acc=$data[0];
  my $Uniprot_id=$data[1];
  my $Uniprot_protein_name=$data[2]; unless($Uniprot_protein_name){$Uniprot_protein_name="NA";}
  my $Uniprot_gene_name=$data[3]; unless($Uniprot_gene_name){$Uniprot_gene_name="NA";}
  my $Uniprot_evidence=$data[4]; unless($Uniprot_evidence){$Uniprot_evidence="NA";}
  my $Uniprot_status=$data[5]; unless($Uniprot_status){$Uniprot_status="NA";}
  $UniProtDetails{$Uniprot_acc}{Uniprot_id}=$Uniprot_id;
  $UniProtDetails{$Uniprot_acc}{Uniprot_protein_name}=$Uniprot_protein_name;
  $UniProtDetails{$Uniprot_acc}{Uniprot_gene_name}=$Uniprot_gene_name;
  $UniProtDetails{$Uniprot_acc}{Uniprot_evidence}=$Uniprot_evidence;
  $UniProtDetails{$Uniprot_acc}{Uniprot_status}=$Uniprot_status;
  }

#Print out results of query in tab-delimited format
#print Dumper (%UniProtDetails);
print "Uniprot_acc\tUniprot_id\tUniprot_protein_name\tUniprot_gene_name\n";
foreach my $uniprot_acc (sort keys %UniProtDetails){
  print "$uniprot_acc\t$UniProtDetails{$uniprot_acc}{'Uniprot_id'}\t$UniProtDetails{$uniprot_acc}{'Uniprot_protein_name'}\t$UniProtDetails{$uniprot_acc}{'Uniprot_gene_name'}\n";
}

exit;
