#!/usr/bin/perl

use strict;
use DBI;
use Data::Dumper;

#Specify mysql connection parameters
my $server = "web02";
my $user_name = "oregano";
my $password = "IFjwqee";
my $db_name = "oregano";

my %Hardison_oreg;

#Create database handle to connect with oreganno database on web02
my $dbh = DBI->connect("DBI:mysql:$db_name:$server",$user_name,$password) or die "Couldn't connect to database: " . DBI->errstr;

#Specify MySQL statement for getting Oreganno record ids for all Hardison records
my $SQL_GET_RECORD_IDS = "SELECT record.id, record.stable_id, dataset.stable_id FROM record, dataset WHERE record.dataset_id=dataset.id AND dataset.stable_id='OREGDS00005'";
#Create statement handle
my $sth_rec_ids = $dbh->prepare($SQL_GET_RECORD_IDS) or die "Couldn't prepare statement: " . $dbh->errstr;

#Execute statement query
$sth_rec_ids -> execute() or die "Couldn't execute statement: " . $sth_rec_ids -> errstr;

#Get results of query and store in hash
while (my $row_ref = $sth_rec_ids -> fetchrow_arrayref()) {
  my $record_id = @{$row_ref}[0];
  my $record_stable_id = @{$row_ref}[1];
  my $dataset_stable_id = @{$row_ref}[2];
  #print "$record_id\t$record_stable_id\t$dataset_stable_id\n";
  $Hardison_oreg{$record_stable_id}{'record_id'}=$record_id;
}

#Finish statement handle
$sth_rec_ids->finish;

#Now, for each record, retrieve comments and extract Hardison ID.
foreach my $record_stable_id (sort keys %Hardison_oreg){
  my $record_id = $Hardison_oreg{$record_stable_id}{'record_id'};
  my $SQL_GET_COMMENT = "SELECT Comment FROM comment WHERE record_id=$record_id";
  my $sth_comment = $dbh->prepare($SQL_GET_COMMENT) or die "Couldn't prepare statement: " . $dbh->errstr;
  $sth_comment -> execute() or die "Couldn't execute statement: " . $sth_comment -> errstr;
  while (my $row_ref = $sth_comment -> fetchrow_arrayref()) {
    my $comment = @{$row_ref}[0];
    #print "$record_stable_id: $comment\n";
    #Get Hardison ID from comment
    if ($comment=~/Penn State Erythroid CRMs Record ID:\s+(\w+)\./){
      my $hardison_id=$1;
      $Hardison_oreg{$record_stable_id}{'Hardison_id'}=$hardison_id;
    }
  }
  $sth_comment->finish;
}
#print Dumper (%Hardison_oreg);

#Now, get evidence (from XML file) for each Hardison record
my %Hardison_evidence;
my $xml_file="/home/obig/Projects/oreganno/Hardison/HardisonXMLtext.xml";
open (XML, $xml_file) or die "can't open $xml_file\n";
undef $/;
my $xml=<XML>;
while ($xml=~m/(\<record\>.+?\<\/record\>)/gs){
  my $record=$1;
  my $hardison_id;
  if ($record=~/\<comment\>Penn State Erythroid CRMs Record ID:\s+(\w+)\./){
    $hardison_id=$1;
  }
  my $evidence_count=0;
  while ($record=~m/(\<evidence\>.+?\<\/evidence\>)/gs){
    $evidence_count++;
    my $evidence=$1;
    my ($comment, $evidenceClassStableId, $evidenceSubtypeStableId, $evidenceTypeStableId, $userName);
    if ($evidence=~/\<comment\>(.+)\<\/comment\>/){$comment=$1;}
    if ($evidence=~/\<evidenceClassStableId\>(.+)\<\/evidenceClassStableId\>/){$evidenceClassStableId=$1;}
    if ($evidence=~/\<evidenceTypeStableId\>(.+)\<\/evidenceTypeStableId\>/){$evidenceTypeStableId=$1;}
    if ($evidence=~/\<evidenceSubtypeStableId\>(.+)\<\/evidenceSubtypeStableId\>/){$evidenceSubtypeStableId=$1;}
    if ($evidence=~/\<userName\>(.+)\<\/userName\>/){$userName=$1;}
    #print "$hardison_id\t$evidence_count\t$evidenceClassStableId\t$evidenceTypeStableId\t$evidenceSubtypeStableId\t$userName\n$comment\n\n";
    #Check comment for problem characters like single quotes
    if ($comment=~/\'/){print "Problem character found in comment\n";}
    $Hardison_evidence{$hardison_id}{$evidence_count}{'comment'}=$comment;
    $Hardison_evidence{$hardison_id}{$evidence_count}{'evidenceClassStableId'}=$evidenceClassStableId;
    $Hardison_evidence{$hardison_id}{$evidence_count}{'evidenceTypeStableId'}=$evidenceTypeStableId;
    $Hardison_evidence{$hardison_id}{$evidence_count}{'evidenceSubtypeStableId'}=$evidenceSubtypeStableId;
    $Hardison_evidence{$hardison_id}{$evidence_count}{'userName'}=$userName;
  }
}
$/="\n";
#print Dumper(%Hardison_evidence);

#Create insert statements to add missing evidence
#Remember to skip the last piece of evidence for each record (as this was already added to the database).

#Need to get evidence type, subtype, and class ids for all stable ids.
my (%evidence_types, %evidence_subtypes, %evidence_classes);
my $SQL_GET_EVIDENCE_TYPES = "SELECT id, stable_id FROM evidence_type";
my $sth_evidence_types = $dbh->prepare($SQL_GET_EVIDENCE_TYPES) or die "Couldn't prepare statement: " . $dbh->errstr;
$sth_evidence_types -> execute() or die "Couldn't execute statement: " . $sth_evidence_types -> errstr;
while (my $row_ref = $sth_evidence_types -> fetchrow_arrayref()) {
  my $evidence_type_id = @{$row_ref}[0];
  my $evidence_type_stable_id = @{$row_ref}[1];
  $evidence_types{$evidence_type_stable_id}=$evidence_type_id;
}
$sth_evidence_types->finish;

my $SQL_GET_EVIDENCE_SUBTYPES = "SELECT id, stable_id FROM evidence_subtype";
my $sth_evidence_subtypes = $dbh->prepare($SQL_GET_EVIDENCE_SUBTYPES) or die "Couldn't prepare statement: " . $dbh->errstr;
$sth_evidence_subtypes -> execute() or die "Couldn't execute statement: " . $sth_evidence_subtypes -> errstr;
while (my $row_ref = $sth_evidence_subtypes -> fetchrow_arrayref()) {
  my $evidence_subtype_id = @{$row_ref}[0];
  my $evidence_subtype_stable_id = @{$row_ref}[1];
  $evidence_subtypes{$evidence_subtype_stable_id}=$evidence_subtype_id;
}
$sth_evidence_subtypes->finish;

my $SQL_GET_EVIDENCE_CLASS = "SELECT id, stable_id FROM evidence_class";
my $sth_evidence_class = $dbh->prepare($SQL_GET_EVIDENCE_CLASS) or die "Couldn't prepare statement: " . $dbh->errstr;
$sth_evidence_class -> execute() or die "Couldn't execute statement: " . $sth_evidence_class -> errstr;
while (my $row_ref = $sth_evidence_class -> fetchrow_arrayref()) {
  my $evidence_class_id = @{$row_ref}[0];
  my $evidence_class_stable_id = @{$row_ref}[1];
  $evidence_classes{$evidence_class_stable_id}=$evidence_class_id;
}
$sth_evidence_class->finish;

#Finally, 
foreach my $record_stable_id (sort keys %Hardison_oreg){
  my $record_id = $Hardison_oreg{$record_stable_id}{'record_id'};
  my $hardison_id= $Hardison_oreg{$record_stable_id}{'Hardison_id'};
  my $num_evidences = keys %{$Hardison_evidence{$hardison_id}};
  #print "$record_stable_id\t$record_id\t$hardison_id\t$num_evidences\n";
  foreach my $evidence_count (sort{$b<=>$a} keys %{$Hardison_evidence{$hardison_id}}){
    if ($evidence_count==$num_evidences){next;} #Skip last piece of evidence
    #print "$record_stable_id\t$record_id\t$hardison_id\t$num_evidences\t$evidence_count\n";
    my $comment=$Hardison_evidence{$hardison_id}{$evidence_count}{'comment'};
    my $evidence_type_id=$evidence_types{$Hardison_evidence{$hardison_id}{$evidence_count}{'evidenceTypeStableId'}};
    my $evidence_subtype_id=$evidence_subtypes{$Hardison_evidence{$hardison_id}{$evidence_count}{'evidenceSubtypeStableId'}};
    my $evidence_class=$evidence_classes{$Hardison_evidence{$hardison_id}{$evidence_count}{'evidenceClassStableId'}};
    my $ADD_EVIDENCE_SQL = "INSERT INTO record_evidence (record_id, evidence_type_id, evidence_subtype_id, evidence_class, entry_date, user_id, evidence_comment) VALUES ('$record_id','$evidence_type_id','$evidence_subtype_id','$evidence_class','2007-04-16','209','$comment')";
    #Print out INSERT statements. These can redirected to a text file and then run by the mysql client.
    #I.e. at command line: "mysql -h web02 -u oregano -pIFjwqee oregano < EvidenceInsertStatements.sql"
    print "$ADD_EVIDENCE_SQL;\n";
  }
}

#Disconnect database handle
$dbh->disconnect;

exit;
