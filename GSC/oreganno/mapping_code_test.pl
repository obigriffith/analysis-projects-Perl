#!/usr/local/bin/perl58 -w

use strict;
use Data::Dumper;
use SOAP::Lite;

my $osa = SOAP::Lite
          -> uri('OregannoServerImpl')
          -> proxy('http://www.oreganno.org/oregano/soap/', timeout => 1000);

my @records;
my @stable_ids=("OREG0000006","OREG0000007");



#For each stable ID use SOAP to get the record
foreach my $stable_id(@stable_ids){
  print "retrieving record via SOAP for $stable_id\n";
  
  my $response = $osa->fetchRecord(SOAP::Data->name(record_stable_id => SOAP::Data->type(string => "$stable_id")));

  if ($response->faultstring) {
    print LONG_LOG $response->faultstring;
    print STDERR $response->faultstring;
    next;
  }
  my $recordref=$response->result;
  push (@records, $recordref);
}

print Dumper (@records);
exit;

if (scalar(@records)==0){
  return undef;
}else{
  return \@records;
}
