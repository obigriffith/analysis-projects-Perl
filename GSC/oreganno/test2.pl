#!/usr/local/bin/perl58
		
use strict;
use Data::Dumper;
use SOAP::Lite;

my $osa = SOAP::Lite
          -> uri('OregannoServerImpl')
          -> proxy('http://www.bcgsc.ca:8080/oregano/soap/');

my $response = $osa->searchRecords(
		SOAP::Data->name(field => SOAP::Data->type(string => "taxon_id")),
#		SOAP::Data->name(field => SOAP::Data->type(string => "taxon_id")),
#                SOAP::Data->name(query => SOAP::Data->type(string => "9606")));
                SOAP::Data->name(query => SOAP::Data->type(string => "6239")));
#                SOAP::Data->name(query => SOAP::Data->type(string => "OREG0000006")));

my %summary;
my %species;
my %types;

#my $response = $osa->getSearchFields();


if ($response->fault) {
  die $response->faultstring;
} else {
  my @results = @{$response->result};
  foreach my $result (@results) {
    #print "$result\n";
    #Get desired info for each record
    my $species = $result->{record}->{speciesName};
    my $stableId = $result->{record}->{stableId};
    my $type = $result->{record}->{type};
   # print "$stableId\t$species\t$type\n";
    $summary{$species}{$type}++;
    $types{$type}++;
    $species{$species}++;
print Dumper ($result);
  }
}

exit;
foreach my $type (sort keys %types){
print "\t$type";
}
print "\n";
foreach my $species (sort keys %species){
  print "$species";
  foreach my $type (sort keys %types){
    my $count = 0;
    if ($summary{$species}{$type}){$count = $summary{$species}{$type};}
    print "\t$count";
  }
  print "\n";
}

