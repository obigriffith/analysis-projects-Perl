#!/usr/local/bin/perl58 -w
use strict;
use LWP::Simple;
use Data::Dumper;
use XML::Simple;

#This script reads the oreganno evidence xml file, converts it to a perl data structure and reorganizes it into a hash with stableId as a key

#This url should always contain the latest xml representation of the oreganno evidence ontology
my $url = 'http://www.oreganno.org/oregano/evidence.xml';
my $evidence_xml = get $url;
die "Couldn't get $url" unless defined $evidence_xml;

#Convert entire xml file to perl data structure.
my $evidence_xml_ref = XMLin($evidence_xml,ForceArray => 1);

#Grab the evidence type section (do evidence classes separate if desired)
my @evidence_types = @{$evidence_xml_ref->{evidenceType}};

#Go through all evidence types and subtypes and collect details of interest. 
#These can just be stuck in a single hash for lookup later
#e.g. $evidence_type_name=$oreganno_evidence{'OREGET00013'}{'name'};

my %oreganno_evidence;
foreach my $evidence_type(@evidence_types){
  my $evidence_type_name = $evidence_type->{name}[0];
  my $evidence_type_stableId = $evidence_type->{stableId}[0];
  my $evidence_type_description = $evidence_type->{description}[0];
  my @evidence_subtypes = $evidence_type->{evidenceSubtype};
  $oreganno_evidence{$evidence_type_stableId}{'name'}=$evidence_type_name;
  $oreganno_evidence{$evidence_type_stableId}{'description'}=$evidence_type_description;
  foreach my $evidence_subtype (@{$evidence_type->{evidenceSubtype}}){
    my $evidence_subtype_name = $evidence_subtype->{name}[0];
    my $evidence_subtype_stableId = $evidence_subtype->{stableId}[0];
    my $evidence_subtype_description = $evidence_subtype->{description}[0];
    $oreganno_evidence{$evidence_subtype_stableId}{'name'}=$evidence_subtype_name;
    $oreganno_evidence{$evidence_subtype_stableId}{'description'}=$evidence_subtype_description;
  }
}
print Dumper(%oreganno_evidence);
