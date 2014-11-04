#!/usr/bin/perl -w

use strict;
use Data::Dumper;
use DBI; #This loads in the DBI module.

my $host = "localhost";
my $user_name = "oregano";
my $password = "IFjwqee";
my $db_name = "oregano";
my $socket_line = "";

my $current_date="2007-09-10";
my $user_id="2"; #obig
my $evidence_code="Predicted automatically by text mining entry";
my $comment="Entered as part of ~58000 publication set from the Stein et al. (2007) text-mining analysis";
my %scores; my %existing_refs;

#First, load in all abstract details to be added to the queue
my $recordfile = "fetch_results_ok_final_minus_tests.txt";
#my $recordfile = "fetch_results_ok_final_test1.txt";
#my $recordfile = "fetch_results_ok_final_test2.txt";
my $scoresfile = "F1000_final_top58k_u.htm";

#Also grab scores from text-mining analysis
open (SCORES, $scoresfile) or die "can't open $scoresfile\n";
while (<SCORES>){
  chomp;
  my @data = split("\t", $_);
  $scores{$data[0]}=$data[1];
}
close SCORES;

# Establish a database connection. DBI returns a database handle object, which we store into $dbh.
my $dbh = DBI->connect("DBI:mysql:host=$host;database=$db_name" . $socket_line, $user_name, $password, {PrintError => 0, RaiseError => 1}) || die("Cannot connect to ORegAnno MySQL database at $host");

#Get a list of all references in the database so that already existing publications can be handled differently
# Prepare the query.
my $REFERENCES_SQL="SELECT id, pubmed_id FROM reference";
my $sth = $dbh->prepare($REFERENCES_SQL) or die "Couldn't prepare statement: " . $dbh->errstr;
# Execute the query.
$sth->execute() or die "Couldn't execute statement: " . $sth->errstr;
#Check for empty result
if ($sth->rows == 0) {print "No record found\n";exit;}
my @data;
while (@data = $sth->fetchrow_array()) {
  my $reference_id = $data[0];
  my $pubmed_id = $data[1];
  $existing_refs{$pubmed_id}=$reference_id;
}
$sth->finish;

#Now, go through each potential pubmed record, determine if it already exists in the database, 
#and then update/insert the appropriate data into the database
open (RECORDS, $recordfile) or die "can't open $recordfile\n";
while (<RECORDS>){
  chomp;
  my @data = split("\t", $_);
  my $pmid=$data[0];
  my $journal=$data[1];
  my $title=$data[2];
  my $date=$data[3];
  my $abstract=$data[4];
  my $score=$scores{$pmid};

  #use quote escaping on potential problem variables
  my $quoted_abstract=$dbh->quote($abstract);
  my $quoted_title=$dbh->quote($title);
  my $quoted_journal=$dbh->quote($journal);

  #Does reference already exist in db?
  if ($existing_refs{$pmid}){
    my $reference_id=$existing_refs{$pmid};
    print "found existing record with pmid: $pmid, reference_id: $reference_id, and score: $score\n";
    #For these, cases just add the score to the existing record
    my $UPDATE_SCORE_SQL="UPDATE publication_queue SET score=\"$score\" WHERE reference_id=\"$reference_id\"";
    print "check: $UPDATE_SCORE_SQL;\n";
    my $sth2 = $dbh->prepare($UPDATE_SCORE_SQL) or die "Couldn't prepare statement: " . $dbh->errstr;
    $sth2->execute() or die "Couldn't execute statement: " . $sth2->errstr;
    $sth2->finish;
  }else{
    my ($reference_id, $pub_queue_id, $queue_pub_state_id);
    #If it doesn't already exist, create a new entry in the reference table.
    print "New record to be added with pmid:$pmid\n";
    my $INSERT_REFERENCE_SQL="INSERT INTO reference SET pubmed_id=\"$pmid\",title=$quoted_title,journal=$quoted_journal,abstract=$quoted_abstract,publication_date=\"$date\"";
    print "check: $INSERT_REFERENCE_SQL;\n";
    my $sth3 = $dbh->prepare($INSERT_REFERENCE_SQL) or die "Couldn't prepare statement: " . $dbh->errstr;
    $sth3->execute() or die "Couldn't execute statement: " . $sth3->errstr;
    $sth3->finish;

    #Now, create a new publication_queue entry (leaving current_queued_publication_state_id empty for now)
    #First, get the new reference_id for the record just created.
    my $REFERENCE_SQL = "SELECT id FROM reference WHERE pubmed_id=\"$pmid\"";
    my $sth4 = $dbh->prepare($REFERENCE_SQL) or die "Couldn't prepare statement: " . $dbh->errstr;
    $sth4->execute() or die "Couldn't execute statement: " . $sth4->errstr;
    if ($sth4->rows == 0) {print "No record found\n";exit;}
    my @data2;
    while (@data2 = $sth4->fetchrow_array()) {
      $reference_id = $data2[0];
    }
    $sth4->finish;

    #Next, create the new publication_queue entry
    my $INSERT_PUB_QUEUE_SQL="INSERT INTO publication_queue SET reference_id=\"$reference_id\",score=\"$score\",evidence_code=\"$evidence_code\",entry_date=\"$current_date\",user_id=\"$user_id\"";
    print "check: $INSERT_PUB_QUEUE_SQL;\n";
    my $sth5 = $dbh->prepare($INSERT_PUB_QUEUE_SQL) or die "Couldn't prepare statement: " . $dbh->errstr;
    $sth5->execute() or die "Couldn't execute statement: " . $sth5->errstr;
    $sth5->finish;

    #Now, find the new publication_queue_id using reference_id
    my $PUB_QUEUE_SQL = "SELECT id from publication_queue WHERE reference_id=\"$reference_id\"";
    my $sth6 = $dbh->prepare($PUB_QUEUE_SQL) or die "Couldn't prepare statement: " . $dbh->errstr;
    $sth6->execute() or die "Couldn't execute statement: " . $sth6->errstr;
    if ($sth6->rows == 0) {print "No record found\n";exit;}
    my @data3;
    while (@data3 = $sth6->fetchrow_array()) {
      $pub_queue_id = $data3[0];
    }
    $sth6->finish;

    #Use the pub_queue_id to create an entry in queued_publication_states
    my $INSERT_QUEUE_PUB_STATE_SQL = "INSERT INTO queued_publication_states SET comment=\"$comment\",state=\"PENDING\",entry_index=\"0\",queued_publication_id=\"$pub_queue_id\",entry_date=\"$current_date\",user_id=\"$user_id\"";
    print "check: $INSERT_QUEUE_PUB_STATE_SQL;\n";
    my $sth7 = $dbh->prepare($INSERT_QUEUE_PUB_STATE_SQL) or die "Couldn't prepare statement: " . $dbh->errstr;
    $sth7->execute() or die "Couldn't execute statement: " . $sth7->errstr;
    $sth7->finish;

    #Finally, get new queued_publication_state_id
    my $QUEUE_PUB_STATE_SQL = "SELECT id from queued_publication_states where queued_publication_id=\"$pub_queue_id\"";
    my $sth8 = $dbh->prepare($QUEUE_PUB_STATE_SQL) or die "Couldn't prepare statement: " . $dbh->errstr;
    $sth8->execute() or die "Couldn't execute statement: " . $sth8->errstr;
    if ($sth8->rows == 0) {print "No record found\n";exit;}
    my @data4;
    while (@data4 = $sth8->fetchrow_array()) {
      $queue_pub_state_id = $data4[0];
    }
    $sth8->finish;

    #and backfill the publication_queue table
    my $UPDATE_PUB_QUEUE_SQL="UPDATE publication_queue SET current_queued_publication_state_id=\"$queue_pub_state_id\" WHERE id=\"$pub_queue_id\"";
    print "check: $UPDATE_PUB_QUEUE_SQL;\n";
    my $sth9 = $dbh->prepare($UPDATE_PUB_QUEUE_SQL) or die "Couldn't prepare statement: " . $dbh->errstr;
    $sth9->execute() or die "Couldn't execute statement: " . $sth9->errstr;
    $sth9->finish;
    #Sleep for a quarter second after each query so that database is not hammered too badly
    select(undef, undef, undef, 0.25);
  }
}
close RECORDS;












#disconnect closes the connection to the database.
$dbh->disconnect;

