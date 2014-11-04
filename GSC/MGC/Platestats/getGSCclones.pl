#!/usr/local/bin/perl -w

use DBI;
use strict;

my $outputfile = "clonelist.txt";
open (CLONELIST, ">>$outputfile") or die "Cannot open file $outputfile\n";

print "\nThis script extracts the list of all the MGC clones that belong to a plate";
print "\nThe results are output to the file clonelist.txt";

print "\nEnter Library: \(eg. IRAK\)\n";
my $library = <STDIN>;
chomp $library;

print "\nEnter Plate Number: \(eg. 75\)\n"; 
my $plate = <STDIN>;
chomp $plate;

print CLONELIST ">>$library$plate\n";

my $dsn;
my $dbh;
dbConnect("sequence");

my $query = "SELECT Clone_Source2_Name FROM Clone WHERE Clone_Source_Library = \"$library\" and Clone_Source_Plate = $plate";

evaluateQuery($query);

close(CLONELIST);

exit;


#######################################################
#connects to database as viewer                       #
#######################################################
sub dbConnect{
  my $database = shift;

  $dsn = "DBI:mysql:$database:athena";
  $dbh = DBI -> connect($dsn, 'viewer', 'viewer', {RaiseError => 1});
}

########################################################
#Sends quert to mySQL database and prints output to file
########################################################

sub evaluateQuery {

  my $query = shift;
  my $sth = $dbh -> prepare("$query");
  $sth -> execute();
  while (my($number)= $sth->fetchrow_array())
    {
      print CLONELIST ">$number\n";
    }

  $sth -> finish();

  return;
}
