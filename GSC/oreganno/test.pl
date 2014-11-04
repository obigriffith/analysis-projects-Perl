#!/usr/local/bin/perl58
		
use strict;
use Data::Dumper;
use SOAP::Lite;

my $osa = SOAP::Lite
          -> uri('OregannoServerImpl')
          -> proxy('http://www.bcgsc.ca:8080/oregano/soap/');

#my $response = $osa->searchRecords(
#		SOAP::Data->name(field => SOAP::Data->type(string => "stable_id")),
#                SOAP::Data->name(query => SOAP::Data->type(string => "OREG*1")));


my $response = $osa->getSearchFields();

if ($response->fault) {
	die $response->faultstring;
} else {
      	my @results = @{$response->result};
        foreach my $result (@results) {
                print Dumper $result;
        }
}
