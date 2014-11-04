#!/usr/bin/perl
#!/usr/local/bin/perl58

use lib "/home/obig/lib/SOAP-Lite-0.66/lib";	
use strict;
use Data::Dumper;
use SOAP::Lite;

my $osa = SOAP::Lite
          -> uri('OregannoServerImpl')
          -> proxy('http://www.oreganno.org/oregano/soap/', timeout => 1000, options => {compress_threshold=>1000});

my $response = $osa->searchRecords(
#		SOAP::Data->name(field => SOAP::Data->type(string => "all")),
		SOAP::Data->name(field => SOAP::Data->type(string => "tf_name")),
#		SOAP::Data->name(field => SOAP::Data->type(string => "taxon_id")),
#                SOAP::Data->name(query => SOAP::Data->type(string => "9606")));
#                SOAP::Data->name(query => SOAP::Data->type(string => "OREG*")));
#                SOAP::Data->name(query => SOAP::Data->type(string => "OREG0000006")));
                SOAP::Data->name(query => SOAP::Data->type(string => "foxa*")));

my %summary;
my %species;
my %types;

if ($response->fault) {
  die $response->faultstring;
} else {
  ## my @results = @{$response->result};
  my $result_str = $response->result;
  my @results = split '\|', $result_str;
  
  foreach my $result (@results) {
    my $response2 = $osa->fetchRecord(SOAP::Data->name(record_stable_id => SOAP::Data->type(string => "$result")));
    if ($response2->fault) {
      die $response2->faultstring;
    } else {
      my $record = $response2->result;
      #print Dumper $record;
      my $species = $record->{record}->{speciesName};
      my $stableId = $record->{record}->{stableId};
      my $type = $record->{record}->{type};
      print "$stableId\t$species\t$type\n";
      $summary{$species}{$type}++;
      $types{$type}++;
      $species{$species}++;
    }
  }
}

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

exit;
