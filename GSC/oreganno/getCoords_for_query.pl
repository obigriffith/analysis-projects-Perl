#!/usr/local/bin/perl58
		
use strict;
use Data::Dumper;
use SOAP::Lite;
use Getopt::Long;

#Initialize command line options
my $tf_query = '';
my $genome_build = '';
my $taxon_id = '';

GetOptions ('tf_query=s'=>\$tf_query,'genome_build=s'=>\$genome_build, 'taxon_id=s'=>\$taxon_id);

unless (($tf_query && $genome_build) || $taxon_id){
  print "\nBasic option(s) missing\n";
  print "You must supply a transcription factor name to query (wildcards allowed) and the genome build of interest.\n";
  print "usage: getCoords_for_query.pl --tf_query foxa* --genome_build MM8 > resultfile.txt\n\n";
  print "alternate arguments: --taxon_id (supply taxon id to determine available genome mapping builds for a particular species\n";
  print "usage: getCoords_for_query.pl --taxon_id 9606\n\n";
  exit;
}

#Create SOAP connection
my $osa = SOAP::Lite
          -> uri('OregannoServerImpl')
          -> proxy('http://www.oreganno.org/oregano/soap/', timeout => 1000);

if ($taxon_id){
  #Display all available mapping builds for the species of interest (by taxon_id)
  my $response1 = $osa->getMappingGenomeBuilds(SOAP::Data->name(taxon_id => SOAP::Data->type(string => "$taxon_id")));
  if ($response1->fault) {
    die $response1->faultstring;
  } else {
    my @mapping_builds = @{$response1->result};
    #print Dumper(@mapping_builds);
    print STDERR "The following builds are available for taxon id: $taxon_id:\n";
    foreach my $mapping_build(@mapping_builds){
      print STDERR "$mapping_build->{buildName}\n";
    }
  }
  exit;
}

#Search database using specific query (in this case, we are searching the tf_name field for a particular phrase)
my $response2 = $osa->searchRecords(
		SOAP::Data->name(field => SOAP::Data->type(string => "tf_name")),
                SOAP::Data->name(query => SOAP::Data->type(string => $tf_query)));

if ($response2->fault) {
  die $response2->faultstring;
} else {
  #The query returns a list of Oreganno stable ids
  my $result_str = $response2->result;
  my @results = split '\|', $result_str;

  #Print headings (make sure these match the print statement below)
  print "stable_id\toutcome\tspecies\tgenename\ttf_name\tsequence\tmapping_genome\tsequenceRegionName\tstart\tend\tstrand\tpmid\tuser\n";
  #For each ORegAnno stable Id get the genomic mappings
  foreach my $stable_id (@results) {
    my $response3 = $osa->getMappings(SOAP::Data->name(record_stable_id => SOAP::Data->type(string => "$stable_id")));
    if ($response3->fault) {
      die $response3->faultstring;
    } else {
      my @mappings = @{$response3->result};
      foreach my $mapping (@mappings){
	my $mapping_status=$mapping->{mappingStatus};
	my $mapping_genome=$mapping->{mappingGenome}->{buildName};
	if ($mapping_genome eq $genome_build){
	  if ($mapping_status eq "MAPPED"){
	    print Dumper($mapping);
	    #If mapping was successful, get chr and coords
	    my $sequenceRegionName = $mapping->{sequenceRegionName};
	    my $start = $mapping->{start};
	    my $end = $mapping->{end};
	    my $strand = $mapping->{strand};
	    ################################
	    #All record details can also be obtained from the 'mapping' object because it contains the 'record' object.
	    #Retrieve any other details desired here. Don't forget to update the 'headings' print statement above.
	    my $sequence = $mapping->{record}->{record}->{sequence};
	    my $tf_name = $mapping->{record}->{record}->{tfName};
	    my $outcome = $mapping->{record}->{record}->{outcome};
	    my $pmid = $mapping->{record}->{record}->{reference};
	    my $species = $mapping->{record}->{record}->{speciesName};
	    my $genename = $mapping->{record}->{record}->{geneName};
	    my $user = $mapping->{record}->{user}->{name};
	    print "$stable_id\t$outcome\t$species\t$genename\t$tf_name\t$sequence\t$mapping_genome\t$sequenceRegionName\t$start\t$end\t$strand\t$pmid\t$user\n";
	    #########################################################
	  }else{
	    print STDERR "No mapping found for $stable_id: $mapping_status\n";
	  }
	}else{
	  print STDERR "wrong mapping build for $stable_id: $mapping_genome\n";
	}
      }
    }
  }
}
