#!/usr/local/bin/perl
      
use strict;
use Data::Dumper;
use SOAP::Lite;

my $osa = SOAP::Lite
          -> uri('OregannoServerImpl')
          -> proxy('http://www.oreganno.org/oregano/soap/');


#For an NCBI Taxon ID get the available mapping builds
my $taxon_id="9606"; #NCBI taxonomy id for Homo sapiens
my $response1 = $osa->getMappingGenomeBuilds(SOAP::Data->type(string => $taxon_id));

if ($response1->fault) {
  die print $response1->faultstring;
}
else {
  my @results = @{$response1->result};
  print "Found " . scalar(@results) . " results\n";
  foreach my $result (@results) {
    print Dumper $result;
  }
}



my $record_id="OREG0000029";
my $response = $osa->getMappings(SOAP::Data->type(string => $record_id));


if ($response->fault) {
   die print $response->faultstring;
}
else {
  my @results = @{$response->result};
  print "Found " . scalar(@results) . " results\n";
  foreach my $result (@results) {
    print Dumper $result;
    my $start=$result->{start};
    my $end=$result->{end};
    my $strand=$result->{strand};
    #print "start: $start\n";
  }
}

