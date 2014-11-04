#!/usr/bin/perl -w

use strict;

use DBI; #This loads in the DBI module.

my $host = "web02";
my $user_name = "oregano";
my $password = "IFjwqee";
my $db_name = "oregano";
my $socket_line = "";

my %summary;
my %species;
my %types;

# Establish a database connection. DBI returns a database handle object, which we store into $dbh.
#my $dbh = DBI->connect("DBI:mysql:$db_name:$host",$user_name,$password) or die "Couldn't connect to database: " . DBI->errstr;
my $dbh = DBI->connect("DBI:mysql:host=$host;database=$db_name" . $socket_line, $user_name, $password, {PrintError => 0, RaiseError => 1}) || die("Cannot connect to ORegAnno MySQL database at $host");

# Prepare the query.
my $sth = $dbh->prepare('select record.stable_id, record.type, species.species_name FROM record,species WHERE record.deprecated_by_record IS NULL AND record.species_id=species.id') or die "Couldn't prepare statement: " . $dbh->errstr;

# Execute the query.
$sth->execute() or die "Couldn't execute statement: " . $sth->errstr;

#Check for empty result
if ($sth->rows == 0) {
  print "No rows matched returned\n\n";
}

# Retrieve and print out results of query
# fetchrow_array returns one of the selected rows from the database.
# Each time through the while loop you get back an array whose elements contain the data from the selected row.
# In this case, the array you get back has three elements: stable id, record type, and species.
my @data;
while (@data = $sth->fetchrow_array()) {
  my $oreg_id = $data[0];
  my $type = $data[1];
  my $species = $data[2];
  #print "$oreg_id: $type\t$species\n";
  $summary{$species}{$type}++;
  $types{$type}++;
  $species{$species}++;
}

#finish tells the database that we have finished retrieving all the data for this query and allows it to reinitialize the handle so that we can execute it again for another query
$sth->finish;

#disconnect closes the connection to the database.
$dbh->disconnect;

#Print out summary
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
