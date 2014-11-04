#!/usr/bin/perl -w
use strict;
use DBI; #This loads in the DBI module.

my $host = "localhost";
my $user_name = "oregano";
my $password = "IFjwqee";
my $db_name = "oregano";
my $socket_line = "";

#Make sure to change this before running.
my $queue_id_listfile="/home/obig/Projects/oreganno/queue/publication_queue_ids_for_pmids_previously_missing_minus_1st.txt";

#Get list of queue ids from file to determine where to insert closure comments
my @queue_ids;
open (QUEUEIDS, $queue_id_listfile) or die "can't open $queue_id_listfile\n";
while (<QUEUEIDS>){
  my $line =$_;
  chomp $line;
  if ($line=~/(\d+)/){
    push (@queue_ids, $1);
  }else{
    print "ID of unexpected format: $line";
  }
}
close(QUEUEIDS);

# Establish a database connection. DBI returns a database handle object, which we store into $dbh.
my $dbh = DBI->connect("DBI:mysql:host=$host;database=$db_name" . $socket_line, $user_name, $password, {PrintError => 0, RaiseError => 1}) || die("Cannot connect to ORegAnno MySQL database at $host");

###Go through list of stable ids from file and delete record and all associated tables###
foreach my $queue_id(@queue_ids){
  print "Preparing to insert closure comment for $queue_id\n";
  # Prepare the query.
  my $INSERT_QUEUE_SQL="INSERT INTO queued_publication_states SET comment='Records for this publication added by xml import for the REDfly dataset', closure_comment='Success - addition of new records', state='CLOSED', entry_index='1', queued_publication_id='$queue_id', entry_date='2007-07-31', user_id='2'";
  print "$INSERT_QUEUE_SQL;\n";
  my $sth = $dbh->prepare($INSERT_QUEUE_SQL) or die "Couldn't prepare statement: " . $dbh->errstr;
  $sth->execute() or die "Couldn't execute statement: " . $sth->errstr;
  $sth->finish;
}

#disconnect closes the connection to the database.
$dbh->disconnect;

