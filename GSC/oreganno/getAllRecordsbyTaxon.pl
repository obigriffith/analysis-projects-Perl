#!/usr/bin/perl -w

use Data::Dumper;
use lib '/home/pubseq/databases/oregblast/lib/SOAP-Lite-0.60/lib';
use SOAP::Lite;
use DBI;

my $osa = SOAP::Lite
  -> uri('OregannoServerImpl')
  -> proxy('http://www.oreganno.org/oregano/soap/', timeout=> 3000);

my $host="web02";
my $socket_line = "";
my $database = "oregano";
my $user = "oregano";
my $password = "IFjwqee";

$dbh = DBI->connect("DBI:mysql:host=$host;database=$database" . $socket_line, $user, $password, {PrintError => 0, RaiseError => 1}) || die("Cannot connect to ORegAnno MySQL database at $host");

#my $taxon_id = "9913";
#my $taxon_id = "9606";
#my $taxon_id = "10090";
#my $taxon_id = "7227";
my $taxon_id = "4932";

my $recordsref = &fetchORegAnnoRecordsAlt($taxon_id);

if (!defined ($recordsref)) {
    $dbh->disconnect();
    &reportError("Could not find any relevant records in ORegAnno");  
}

my @records = @{$recordsref};
print Dumper(@records);
#foreach my $record (@records){
#  my $cleanrecord = @{$record}[0];
  #print "preparing to map $cleanrecord->{'record'}->{'stableId'}\n";
  #print Dumper($cleanrecord);
#}
foreach my $record (@records){
  print "preparing to map $record->{'record'}->{'stableId'}\n";
}



my $recordsref2 = &fetchORegAnnoRecords($taxon_id);
#print Dumper($recordsref2);

my @records2 = @{$recordsref2};
#print Dumper(@records2);

##############
## DESCRIPTION: Get the ORegAnno records by taxon id (but query by stable id one at a time to avoid timeout problems)
## NOTE: Only non-deprecated records are retrieved
##############
sub fetchORegAnnoRecordsAlt{
  my $taxon_id = shift;
  my @records;

  #Get all oreg ids for a particular taxon id
  my @stable_ids;
  my $SQL_GET_ALL_OREG = "select record.stable_id from record, species WHERE deprecated_by_record IS NULL AND record.species_id=species.id AND species.taxon_id=\"$taxon_id\" ORDER BY record.stable_id";
  my $sth_rec = $dbh->prepare($SQL_GET_ALL_OREG) or die "Couldn't prepare statement: " . $dbh->errstr;
  $sth_rec -> execute() or die "Couldn't execute statement: " . $sth_rec -> errstr;

  while (my $row_ref = $sth_rec -> fetchrow_arrayref()) {
    my $stable_id = @{$row_ref}[0];
    push (@stable_ids, $stable_id);
  }


  #For each stable ID use SOAP to get the record
  foreach my $stable_id(@stable_ids){
    #print "retrieving record via SOAP for $stable_id\n";
    my $response = $osa->searchRecords(
				       SOAP::Data->name(field => SOAP::Data->type(string => "stable_id")),
				       SOAP::Data->name(query => SOAP::Data->type(string => "$stable_id")));

    if ($response->faultstring) {
      #print LONG_LOG $response->faultstring;
      #print STDERR $response->faultstring;
      next;
    }

    my $responseref=$response->result;
    my $recordref=@{$responseref}[0];
    #print Dumper($response->result);
#    push (@records, $response->result);
    push (@records, $recordref);
  }

  if (scalar(@records)==0){
    return undef;
  }else{
    return \@records;
  }
}


sub fetchORegAnnoRecords{
  my $taxon_id = shift;
  my $response = $osa->searchRecords(
				   SOAP::Data->name(field => SOAP::Data->type(string => "taxon_id")),
				   SOAP::Data->name(query => SOAP::Data->type(string => "$taxon_id")));
 
  my $recordref=$response->result;
#  print Dumper($recordref);

  return $response->result;


}
