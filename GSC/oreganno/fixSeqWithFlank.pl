#!/usr/bin/perl -w

use DBI;
use strict;
use Data::Dumper;
use Time::HiRes qw(usleep ualarm gettimeofday tv_interval);

my $host = "web02";
my $user_name = "oregano";
my $password = "IFjwqee";
my $db_name = "oregano";
my $socket_line = "";

my $outfile="fixed_sequences.txt";
my $sql_update_file="sequence_flank_update.sql";
open (OUTFILE, ">$outfile") or die "can't open $outfile for write\n";
open (SQL, ">$sql_update_file") or die "can't open $sql_update_file for write\n";

#Establish a database connection. DBI returns a database handle object, which we store into $dbh.
my $dbh = DBI->connect("DBI:mysql:host=$host;database=$db_name" . $socket_line, $user_name, $password, {PrintError => 0,
RaiseError => 1}) || die("Cannot connect to ORegAnno MySQL database at $host");

my %sequences;

#First get all regulatory sequences for CTCF dataset
my @sequence_data;
my $sequence_SQL = "SELECT record.id,sequence.sequence,sequence.id FROM record,sequence WHERE dataset_id=\"10\" and record.regulatory_sequence=sequence.id";
my $sth1 = $dbh-> prepare($sequence_SQL) or die "Couldn't prepare statement: " . $dbh->errstr;
$sth1->execute() or die "Couldn't execute statement: " . $sth1->errstr;
if ($sth1->rows == 0){
  print "No record_id found\n";
  exit;
}
while (@sequence_data = $sth1->fetchrow_array()){
  $sequences{$sequence_data[0]}{'sequence'}=$sequence_data[1];
  $sequences{$sequence_data[0]}{'sequence_id'}=$sequence_data[2];
}
$sth1->finish;

#Then, get all sequence_with_flanks for CTCF dataset
my @sequence_flank_data;
my $sequence_flank_SQL = "SELECT record.id,sequence.sequence,sequence.id FROM record,sequence WHERE dataset_id=\"10\" and record.regulatory_sequence_with_flank=sequence.id";
my $sth2 = $dbh-> prepare($sequence_flank_SQL) or die "Couldn't prepare statement: " . $dbh->errstr;
$sth2->execute() or die "Couldn't execute statement: " . $sth2->errstr;
if ($sth2->rows == 0){
  print "No record_id found\n";
  exit;
}
while (@sequence_flank_data = $sth2->fetchrow_array()){
  $sequences{$sequence_flank_data[0]}{'sequence_flank'}=$sequence_flank_data[1];
  $sequences{$sequence_flank_data[0]}{'sequence_flank_id'}=$sequence_flank_data[2];
}
$sth2->finish;

#Now, go through each record, check its sequence against sequence_with_flank and update the latter if necessary
#In some cases (where the regulatory_sequence is very long, the regulatory_sequence_with_flank is the same. Nothing needs to be done for these.
#Also need to watch for the possibility of multiple sequence matches in the sequence with flank.

foreach my $record (sort keys %sequences){
  my $sequence_flank_fixed;
  my $sequence=$sequences{$record}{'sequence'};
  my $sequence_flank=$sequences{$record}{'sequence_flank'};
  my $sequence_flank_id=$sequences{$record}{'sequence_flank_id'};
  #print "Record: $record\nComparing:\nsequence: $sequence\nsequence_flank: $sequence_flank\n";

  #If the sequence and sequence with flank are identical, nothing needs to be done.
  if ($sequence eq $sequence_flank){
    print "sequence and sequence_flank are identical. No update needed. Skipping to next record\n";
    $sequence_flank_fixed=$sequence;
    print OUTFILE "$sequence\t$sequence_flank_fixed\n";
    &updateSequenceFlank($sequence_flank_fixed,$sequence_flank_id);
    next;
  }

  #For long sequences, just use the sequence as sequence_with_flank
  if (length($sequence)>=100){
    $sequence_flank_fixed=$sequence;
    print "sequence is over 100 bases. Using this as sequence with flank.\n";
    print OUTFILE "$sequence\t$sequence_flank_fixed\n";
    &updateSequenceFlank($sequence_flank_fixed,$sequence_flank_id);
    next;
  }

  #The problem with the sequence seems to be that the first base is not uppercase in the sequence with flank.
  my $firstbase = substr($sequence, 0, 1);
  my $firstbase_lc=lc($firstbase);
  my $problem_sequence=$sequence;
  substr($problem_sequence, 0, 1) = $firstbase_lc;

  #Check for number of matches
  my $match_count=0;
  while ($sequence_flank=~/$problem_sequence/g){
    $match_count++;
  }
  print "match_count: $match_count\n";

  #If no sequence found in sequence_flank, print error and exit
  if ($match_count==0){
    print "sequence still not found\n";
    exit;
  }

  if ($match_count==1){
    if ($sequence_flank=~/(\w+)$problem_sequence(\w+)/g){
      print "sequence found in sequence_flank\n";
      my $left_flank=$1;
      my $right_flank=$2;
      $sequence_flank_fixed="$left_flank"."$sequence"."$right_flank";
      print "Repairing sequence with flank\n";
      print OUTFILE "$sequence\t$sequence_flank_fixed\n";
      &updateSequenceFlank($sequence_flank_fixed,$sequence_flank_id);
      next;
    }
  }

  #If more than one hit is found, print error and exit.
  if ($match_count>1){
    print "multiple matches found\n";
    exit;
  }
}
close OUTFILE;
close SQL;
exit;


sub updateSequenceFlank{
my $sequence_flank = shift;
my $sequence_flank_id = shift;

my $UPDATE_SEQUENCE = "UPDATE sequence SET sequence=\"$sequence_flank\" WHERE id=\"$sequence_flank_id\"";
print SQL $UPDATE_SEQUENCE, ";\n";
usleep(100000);
my $sth3 = $dbh -> prepare($UPDATE_SEQUENCE) or die "Couldn't prepare statement: " . $dbh->errstr;
$sth3->execute() or die "Couldn't execute statement: " . $sth3->errstr;
if ($sth3->rows == 0 )
{
  print "No record found\n";
  exit;
}
$sth3->finish;



}
