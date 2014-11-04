#!/usr/bin/perl -w

use strict;
use Getopt::Long;
use Data::Dumper;
use DBI; #This loads in the DBI module.

my $host = "localhost";
my $user_name = "oregano";
my $password = "IFjwqee";
my $db_name = "oregano";
my $socket_line = "";

my ($stable_id_listfile, $delete);

GetOptions ('file=s'=>\$stable_id_listfile,
	    'delete=s'=>\$delete);

unless ($stable_id_listfile && $delete){
  print "usage: deleteRecordsFromDBbyStableId.pl --file my_stable_id_list.txt --delete FALSE\n";
  print "Supply file with list of OREG ids (one per line)\n";
  print "Run with 'delete FALSE' to review delete statements. Only change to TRUE when certain everything is ok\n";
  print "WARNING: THIS WILL DELETE RECORDS FROM DATABASE. USE WITH EXTREME CAUTION\n";
  exit;
}

#Get list of stable ids from file to determine records to delete from database
my @stable_ids;
open (STABLEIDS, $stable_id_listfile) or die "can't open $stable_id_listfile\n";
while (<STABLEIDS>){
  my $line =$_;
  chomp $line;
  if ($line=~/(OREG\d+)/){
    push (@stable_ids, $1);
  }else{
    print "ID of unexpected format: $line";
  }
}
close(STABLEIDS);

# Establish a database connection. DBI returns a database handle object, which we store into $dbh.
my $dbh = DBI->connect("DBI:mysql:host=$host;database=$db_name" . $socket_line, $user_name, $password, {PrintError => 0, RaiseError => 1}) || die("Cannot connect to ORegAnno MySQL database at $host");

###Go through list of stable ids from file and delete record and all associated table entries###
foreach my $stable_id(@stable_ids){
  my ($record_id, $sequence_id, $sequence_with_flank_id, $sequence_search_space_id);
  my @sequences_to_del;
  print "Preparing to delete record for $stable_id\n";
  ###First, get the record_id (and sequence ids) for the stable_id###
  ###Also retrieve ids for regulatory_sequence, regulatory_sequence_with_flank, and sequence_search_space

  #Prepare the query.
  my $RECORD_ID_SQL="SELECT record.id, record.regulatory_sequence, record.regulatory_sequence_with_flank, record.sequence_search_space FROM record WHERE record.stable_id=\"$stable_id\"";
  my $sth = $dbh->prepare($RECORD_ID_SQL) or die "Couldn't prepare statement: " . $dbh->errstr;
  $sth->execute() or die "Couldn't execute statement: " . $sth->errstr;
  #Check for empty result
  if ($sth->rows == 0) {print "No record found\n";next;}
  my @data;
  while (@data = $sth->fetchrow_array()) {
    $record_id = $data[0];
    $sequence_id = $data[1];
    $sequence_with_flank_id = $data[2];
    $sequence_search_space_id = $data[3];
    push (@sequences_to_del, ($sequence_id, $sequence_with_flank_id, $sequence_search_space_id));
    print "Record id found: $record_id\n";
  }
  $sth->finish;

  ###Use record_id to delete data from tables that point to that record id
  ###Delete any mapping records
  my $MAPPING_SQL="SELECT id FROM mapping WHERE mapping.record_id=\"$record_id\"";
  my $sth2 = $dbh->prepare($MAPPING_SQL) or die "Couldn't prepare statement: " . $dbh->errstr;
  $sth2->execute() or die "Couldn't execute statement: " . $sth2->errstr;
  if ($sth2->rows == 0) {
    print "No mappings found\n";
  }else{
    my $mapping_id;
    my @mapping_data;
    while (@mapping_data = $sth2->fetchrow_array()) {
      $mapping_id = $mapping_data[0];
      print "Mapping record found: $mapping_id where record_id=$record_id\n";
    }
    $sth2->finish;
    #DELETE ALL MAPPING RECORDS FOR THIS RECORD
    print "Deleting mapping records where record_id=$record_id\n";
    my $MAPPING_DEL_SQL="DELETE FROM mapping WHERE mapping.record_id=\"$record_id\"";
    print "CHECK SQL:  $MAPPING_DEL_SQL;\n";
    if ($delete eq "TRUE"){
      my $sth2_del = $dbh->prepare($MAPPING_DEL_SQL) or die "Couldn't prepare statement: " . $dbh->errstr;
      $sth2_del->execute() or die "Couldn't execute statement: " . $sth2_del->errstr;
      $sth2_del->finish;
    }
  }

  ###Delete any comments
  my $COMMENT_SQL="SELECT id FROM comment WHERE comment.record_id=\"$record_id\"";
  my $sth3 = $dbh->prepare($COMMENT_SQL) or die "Couldn't prepare statement: " . $dbh->errstr;
  $sth3->execute() or die "Couldn't execute statement: " . $sth3->errstr;
  if ($sth3->rows == 0) {
    print "No comments found\n";
  }else{
    my $comment_id;
    my @comment_data;
    while (@comment_data = $sth3->fetchrow_array()) {
      $comment_id = $comment_data[0];
      print "Comment record found: $comment_id where record_id=$record_id\n";
    }
    $sth3->finish;
    #DELETE ALL COMMENTS FOR THIS RECORD
    print "Deleting comments where record_id=$record_id\n";
    my $COMMENT_DEL_SQL="DELETE FROM comment WHERE comment.record_id=\"$record_id\"";
    print "CHECK SQL:  $COMMENT_DEL_SQL;\n";
    if ($delete eq "TRUE"){
      my $sth3_del = $dbh->prepare($COMMENT_DEL_SQL) or die "Couldn't prepare statement: " . $dbh->errstr;
      $sth3_del->execute() or die "Couldn't execute statement: " . $sth3_del->errstr;
      $sth3_del->finish;
    }
  }

  ###Delete any meta records
  my $META_SQL="SELECT id FROM meta WHERE meta.record_id=\"$record_id\"";
  my $sth4 = $dbh->prepare($META_SQL) or die "Couldn't prepare statement: " . $dbh->errstr;
  $sth4->execute() or die "Couldn't execute statement: " . $sth4->errstr;
  if ($sth4->rows == 0) {
    print "No meta data found\n";
  }else{
    my $meta_id;
    my @meta_data;
    while (@meta_data = $sth4->fetchrow_array()) {
      $meta_id = $meta_data[0];
      print "Meta data found with id: $meta_id where record_id=$record_id\n";
    }
    $sth4->finish;
    #DELETE ALL META DATA FOR THIS RECORD
    print "Deleting meta data where record_id=$record_id\n";
    my $META_DEL_SQL="DELETE FROM meta WHERE meta.record_id=\"$record_id\"";
    print "CHECK SQL:  $META_DEL_SQL;\n";
    if ($delete eq "TRUE"){
      my $sth4_del = $dbh->prepare($META_DEL_SQL) or die "Couldn't prepare statement: " . $dbh->errstr;
      $sth4_del->execute() or die "Couldn't execute statement: " . $sth4_del->errstr;
      $sth4_del->finish;
    }
  }

  ###Delete any record_evidence
  my $EVIDENCE_SQL="SELECT id FROM record_evidence WHERE record_evidence.record_id=\"$record_id\"";
  my $sth5 = $dbh->prepare($EVIDENCE_SQL) or die "Couldn't prepare statement: " . $dbh->errstr;
  $sth5->execute() or die "Couldn't execute statement: " . $sth5->errstr;
  if ($sth5->rows == 0) {
    print "No record evidence found\n";
  }else{
    my $record_evidence_id;
    my @evidence_data;
    while (@evidence_data = $sth5->fetchrow_array()) {
      $record_evidence_id = $evidence_data[0];
      print "Record evidence found with id: $record_evidence_id where record_id=$record_id\n";
    }
    $sth5->finish;
    #DELETE ALL RECORD EVIDENCE FOR THIS RECORD
    print "Deleting record evidence data where record_id=$record_id\n";
    my $EVIDENCE_DEL_SQL="DELETE FROM record_evidence WHERE record_evidence.record_id=\"$record_id\"";
    print "CHECK SQL:  $EVIDENCE_DEL_SQL;\n";
    if ($delete eq "TRUE"){
      my $sth5_del = $dbh->prepare($EVIDENCE_DEL_SQL) or die "Couldn't prepare statement: " . $dbh->errstr;
      $sth5_del->execute() or die "Couldn't execute statement: " . $sth5_del->errstr;
      $sth5_del->finish;
    }
  }

  ###Delete any score records
  my $SCORE_SQL="SELECT id FROM score WHERE score.record_id=\"$record_id\"";
  my $sth6 = $dbh->prepare($SCORE_SQL) or die "Couldn't prepare statement: " . $dbh->errstr;
  $sth6->execute() or die "Couldn't execute statement: " . $sth6->errstr;
  if ($sth6->rows == 0) {
    print "No score records found\n";
  }else{
    my $score_id;
    my @score_data;
    while (@score_data = $sth6->fetchrow_array()) {
      $score_id = $score_data[0];
      print "Score found with id: $score_id where record_id=$record_id\n";
    }
    $sth6->finish;
    #DELETE ALL SCORE RECORDS FOR THIS RECORD
    print "Deleting score data where record_id=$record_id\n";
    my $SCORE_DEL_SQL="DELETE FROM score WHERE score.record_id=\"$record_id\"";
    print "CHECK SQL:  $SCORE_DEL_SQL;\n";
    if ($delete eq "TRUE"){
      my $sth6_del = $dbh->prepare($SCORE_DEL_SQL) or die "Couldn't prepare statement: " . $dbh->errstr;
      $sth6_del->execute() or die "Couldn't execute statement: " . $sth6_del->errstr;
      $sth6_del->finish;
    }
  }

  ###Delete any variation records
  my $VARIATION_SQL="SELECT id, reference_sequence, variant_sequence FROM variation WHERE variation.record_id=\"$record_id\"";
  my $sth7 = $dbh->prepare($VARIATION_SQL) or die "Couldn't prepare statement: " . $dbh->errstr;
  $sth7->execute() or die "Couldn't execute statement: " . $sth7->errstr;
  if ($sth7->rows == 0) {
    print "No variation records found\n";
  }else{
    my ($variation_id, $reference_sequence_id, $variant_sequence_id);
    my @variation_data;
    while (@variation_data = $sth7->fetchrow_array()) {
      $variation_id = $variation_data[0];
      $reference_sequence_id = $variation_data[1];
      $variant_sequence_id = $variation_data[2];
      print "Variation found with id: $variation_id where record_id=$record_id\n";
      push (@sequences_to_del, ($reference_sequence_id, $variant_sequence_id));
    }
    $sth7->finish;

    #DELETE ALL VARIATION RECORDS FOR THIS RECORD
    print "Deleting variation data where record_id=$record_id\n";
    my $VARIATION_DEL_SQL="DELETE FROM variation WHERE variation.record_id=\"$record_id\"";
    print "CHECK SQL:  $VARIATION_DEL_SQL;\n";
    if ($delete eq "TRUE"){
      my $sth7_del = $dbh->prepare($VARIATION_DEL_SQL) or die "Couldn't prepare statement: " . $dbh->errstr;
      $sth7_del->execute() or die "Couldn't execute statement: " . $sth7_del->errstr;
      $sth7_del->finish;
    }
  }

  ###################################################################
  #delete records from sequence table for all sequence ids retrieved above
  print "Deleting all sequence data where record_id=$record_id\n";
  foreach my $sequence_id (@sequences_to_del){
    if ($sequence_id==1){#sequence_id=1 is a dummy sequence used to specify and empty sequence record. This is needed for other records
      print "Skipping sequence_id=$sequence_id (dummy sequence record)\n";
      next;
    }else{
      my $SEQUENCE_DEL_SQL="DELETE FROM sequence WHERE sequence.id=\"$sequence_id\"";
      print "CHECK SQL: $SEQUENCE_DEL_SQL;\n";
      if ($delete eq "TRUE"){
	my $sth8_del = $dbh->prepare($SEQUENCE_DEL_SQL) or die "Couldn't prepare statement: " . $dbh->errstr;
	$sth8_del->execute() or die "Couldn't execute statement: " . $sth8_del->errstr;
	$sth8_del->finish;
      }
    }
  }

  ###################################################################

  ###Finally, delete the record itself
  print "Deleting record where record_id=$record_id\n";
  my $RECORD_DEL_SQL="DELETE FROM record WHERE id=\"$record_id\"";
  print "CHECK SQL:  $RECORD_DEL_SQL;\n";
  if ($delete eq "TRUE"){
    my $sth9_del = $dbh->prepare($RECORD_DEL_SQL) or die "Couldn't prepare statement: " . $dbh->errstr;
    $sth9_del->execute() or die "Couldn't execute statement: " . $sth9_del->errstr;
    $sth9_del->finish;
  }
print "------------------------\n\n"
}

#disconnect closes the connection to the database.
$dbh->disconnect;

