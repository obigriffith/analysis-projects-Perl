#!/usr/local/bin/perl58
		
use strict;
use Data::Dumper;
use SOAP::Lite;

my $osa = SOAP::Lite
          -> uri('OregannoServerImpl')
          -> proxy('http://www.oreganno.org/oregano/soap/', timeout => 1000);

my $response = $osa->searchRecords(
                SOAP::Data->name(field => SOAP::Data->type(string => "tf_name")),
                SOAP::Data->name(query => SOAP::Data->type(string => "CTCF")));

if ($response->fault) {
  die $response->faultstring;
} else {
  my $result_str = $response->result;
  my @results = split '\|', $result_str;
  print Dumper (@results);

  foreach my $result (@results) {
    print "retrieving record details for $result\n";
    my $response2 = $osa->fetchRecord(SOAP::Data->name(record_stable_id => SOAP::Data->type(string => "$result")));
    if ($response2->fault) {
      die $response2->faultstring;
    } else {
      my $record = $response2->result;
      print Dumper($record);
    }
  }
}
exit;
