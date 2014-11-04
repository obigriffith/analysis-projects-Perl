#!/usr/bin/perl -w
use strict;
use Data::Dumper;
use DBI;
use lib "/home/obig/lib/perl/XML-Simple-2.14/lib";
use XML::Simple;
use Getopt::Long;

my ($xmlfile, $write, $formatted_date);
GetOptions ('file=s'=>\$xmlfile,
	    'date=s'=>\$formatted_date,
	    'write=s'=>\$write);

unless($xmlfile){&printUsage();}
unless($write eq "TRUE" || $write eq "FALSE"){printUsage();}
unless($formatted_date){printUsage();}
unless($formatted_date=~/\d{4}\-\d{2}\-\d{2}/){printUsage();}
unless(-e $xmlfile){print "$xmlfile does not exist\n";exit;}

my $host = "web02";
my $user_name = "oregano";
my $password = "IFjwqee";
my $db_name = "oregano";
my $socket_line = "";


#Establish a database connection. DBI returns a database handle object, which we store into $dbh.
my $dbh = DBI->connect("DBI:mysql:host=$host;database=$db_name" . $socket_line, $user_name, $password, {PrintError => 0,
RaiseError => 1}) || die("Cannot connect to ORegAnno MySQL database at $host");


#creating a hash for the user id and name
my $user_id = "SELECT name,id FROM user";
my $sth15 = $dbh-> prepare($user_id) or die "Couldn't prepare statement: " . $dbh->errstr;
$sth15->execute() or die "Couldn't execute statement: " . $sth15->errstr;
if ($sth15->rows == 0)
{
    print "No record found\n";
    exit;
}
my @data15;
my %user_ids;
while (@data15 = $sth15->fetchrow_array())
{
    $user_ids{$data15[0]}= $data15[1];
}
$sth15->finish;
#print "$user_ids{'shaunmahony'}\n";


#creating a hash for the cell type external id and id
my $celltype_id = "SELECT  external_id,id FROM celltype";
my $sth3 = $dbh-> prepare($celltype_id) or die "Couldn't prepare statement: " . $dbh->errstr;
$sth3->execute() or die "Couldn't execute statement: " . $sth3->errstr;
if ($sth3->rows == 0)
{
    print "No record found\n";
    exit;
}
my @data3;
my %celltype_ids;
while (@data3 = $sth3->fetchrow_array())
{
    $celltype_ids{$data3[0]}= $data3[1];
}
$sth3->finish;
#print "$celltype_ids{'EV:0200032'}\n";

#creating a hash for evidence-type stable id and id
my $evidencetype_id = "SELECT  stable_id,id FROM evidence_type";
my $sth4 = $dbh-> prepare($evidencetype_id) or die "Couldn't prepare statement: " . $dbh->errstr;
$sth4->execute() or die "Couldn't execute statement: " . $sth4->errstr;
if ($sth4->rows ==0)
{
    print "No record found\n";
    exit;
}
my @data4;
my %evidencetype_ids;
while (@data4 = $sth4->fetchrow_array())
{
    $evidencetype_ids{$data4[0]}= $data4[1];
}
$sth4->finish;
#print "$evidencetype_ids{'OREGET00003'}\n";

#creating a hash for evidence-subtype stable id and id
my $evidencesubtype_id = "SELECT  stable_id,id FROM evidence_subtype";
my $sth5 = $dbh-> prepare($evidencesubtype_id) or die "Couldn't prepare statement: " . $dbh->errstr;
$sth5->execute() or die "Couldn't execute statement: " . $sth5->errstr;
if ($sth5->rows ==0)
{
    print "No record found\n";
    exit;
}
my @data5;
my %evidencesubtype_ids;
while (@data5 = $sth5->fetchrow_array())
{
    $evidencesubtype_ids{$data5[0]}= $data5[1];
}
$sth5->finish;
#print "$evidencesubtype_ids{'OREGES00070'}\n";

#creating a hash for evidence class stable id and id
my $evidenceclass_id = "SELECT  stable_id,id FROM evidence_class";
my $sth6 = $dbh-> prepare($evidenceclass_id) or die "Couldn't prepare statement: " . $dbh->errstr;
$sth6->execute() or die "Couldn't execute statement: " . $sth6->errstr;
if ($sth6->rows == 0)
{
    print "No record found\n";
    exit;
}
my @data6;
my %evidenceclass_ids;
while (@data6 = $sth6->fetchrow_array())
{
    $evidenceclass_ids{$data6[0]}= $data6[1];
}
$sth6->finish;
#print "$evidenceclass_ids{'OREGEC00001'}\n";

#creating a hash for the species id and taxonid
my $species_id = "SELECT taxon_id,id FROM species";
my $sth16 = $dbh-> prepare($species_id) or die "Couldn't prepare statement: " . $dbh->errstr;
$sth16->execute() or die "Couldn't execute statement: " . $sth16->errstr;
if ($sth16->rows == 0)
{
    print "No record found\n";
    exit;
}
my @data16;
my %species_ids;
while (@data16 = $sth16->fetchrow_array())
{
    $species_ids{$data16[0]}= $data16[1];
}
$sth16->finish;
#print "$species_ids{'4932'}\n";

#creating a hash for referenceid and pubmed_id
my $reference_id = "SELECT pubmed_id,id FROM reference";
my $sth17 = $dbh-> prepare($reference_id) or die "Couldn't prepare statement: " . $dbh->errstr;
$sth17->execute() or die "Couldn't execute statement: " . $sth17->errstr;
if ($sth17->rows == 0)
{
    print "No record found\n";
    exit;
}
my @data17;
my %reference_ids;
while (@data17 = $sth17->fetchrow_array())
{
    $reference_ids{$data17[0]}= $data17[1];
}
$sth17->finish;
#print "$reference_ids{'16522208'}\n";

#creating a hash for the dataset id and stableid
my $dataset_id = "SELECT stable_id,id FROM dataset";
my $sth18 = $dbh-> prepare($dataset_id) or die "Couldn't prepare statement: " . $dbh->errstr;
$sth18->execute() or die "Couldn't execute statement: " . $sth18->errstr;
if ($sth18->rows == 0)
{
    print "No record found\n";
    exit;
}
my @data18;
my %dataset_ids;
while (@data18 = $sth18->fetchrow_array())
{
    $dataset_ids{$data18[0]}= $data18[1];
}
$sth18->finish;
#print "$dataset_ids{'OREGDS00010'}\n";

#Convert entire xml file to perl data structure.
my $xml_ref = XMLin($xmlfile,ForceArray => 1,suppressempty=>'');

#getting the user name
my $username = $xml_ref -> {userName}[0];
unless($user_ids{$username}){print "$username does not exist in database\n";exit;}
my $userid = $user_ids{$username};

#get the species id for each species in the speciesSet fot the xml file
my %species_set_ids;
my $speciesSet = $xml_ref -> {speciesSet}[0];
my @species = @{$speciesSet -> {species}};
foreach my $species (@species){
  my $taxon_id = $species -> {taxonId}[0];
  my $species_name = $species -> {name}[0];
  unless ($species_ids{$taxon_id}){print "species for taxon id $taxon_id does not exist in database\n"; exit;}
  my $speciesid = $species_ids{$taxon_id};
  $species_set_ids{$species_name}=$speciesid;
}

#putting all the records in the xml file into an array
my $recordSet = $xml_ref -> {recordSet}[0];
my @records = @{$recordSet -> {record}};
#print Dumper(@records);


#extracting info from each record in the xml file
foreach my $record(@records)
{  
   select(undef, undef, undef, 0.1);
   my $geneId = $record -> {geneId}[0];
   my $geneName = $record -> {geneName}[0];
   my $geneSource = $record -> {geneSource}[0];
   my $geneVersion = $record -> {geneVersion}[0];
   my $outcome = $record -> {outcome}[0];
   my $speciesName = $record -> {speciesName}[0];
   my $speciesid = $species_set_ids{$speciesName};
   my $tfId = $record -> {tfId}[0];
   my $tfName = $record -> {tfName}[0];
   my $tfSource = $record -> {tfSource}[0];
   my $tfVersion = $record -> {tfVersion}[0];
   my $lociName = $record -> {lociName}[0];
   my $type = $record -> {type}[0];
   my $reference = $record -> {reference}[0];
   unless ($reference_ids{$reference}){print "reference does not exist for PMID $reference. Make sure that it has been added to the queue\n";exit;}
   my $referenceid = $reference_ids{$reference};
   #print $referenceid, "\n";
   my $dataset = $record -> {dataset}[0];
   my $dataset_id;
   if($dataset){
     unless ($dataset_ids{$dataset}){print "dataset does not exist for $dataset in database\n";exit;}
     $dataset_id = $dataset_ids{$dataset};
     #print $dataset_id, "\n";
   }else{
     $dataset_id="NULL";
   }

   #Insert sequence details into sequence table and obtain sequence ids
   my $sequence_ref = $record -> {sequence}[0];
   my $sequenceWithFlank_ref = $record -> {sequenceWithFlank}[0];
   my $searchSpace_ref = $record -> {searchSpace}[0];
   #Set sequence ids to 1 (place-holder for 'EMPTY')
   my $regulatory_sequence_id=1;
   my $regulatory_sequence_with_flank_id=1;
   my $sequence_search_space_id=1;

   if($sequence_ref){$regulatory_sequence_id=&insertSequence($sequence_ref);}
   if($sequenceWithFlank_ref){$regulatory_sequence_with_flank_id=&insertSequence($sequenceWithFlank_ref);}
   if($searchSpace_ref){$sequence_search_space_id=&insertSequence($searchSpace_ref);}

   #looking up all the stable_id's in the database
   my $stable_ids = "SELECT stable_id FROM record";
   my $sth1 = $dbh-> prepare($stable_ids) or die "Couldn't prepare statement: " . $dbh->errstr;
   $sth1->execute() or die "Couldn't execute statement: " . $sth1->errstr;
   if ($sth1->rows ==0){print "No record found\n";exit;}

   #looking for the biggest stable_id currently in the database
   my @data1;
   my @stable_ids;
   my $i=0;
   while (@data1 = $sth1->fetchrow_array())
   {
       $stable_ids[$i] = $data1[0];
       $i++;
   }
   $sth1->finish;
   #print Dumper (@stable_ids); 
 
  
   #Get largest current stable id and its number without OREG or leading zeros
   my $max_stable_id;
   my $max_stable_id_num=0;
   foreach my $stable_id(@stable_ids)
   {
       if ($stable_id=~/OREG0+(\d+)/)
       {
	   my $stable_id_num=$1;
	   if ($stable_id_num>$max_stable_id_num)
	   {
	       $max_stable_id_num=$stable_id_num;
	       $max_stable_id=$stable_id;
	   }
       }
   }
   my $new_stable_id_num=$max_stable_id_num+1;
   my $formatted_new_stable_id_num = sprintf("%07d", $new_stable_id_num);
   my $new_stable_id = "OREG"."$formatted_new_stable_id_num";
   print "creating record $new_stable_id\n";

   #insert the record into the record table
   my $INSERT_INTO_RECORD_SQL = "INSERT INTO record SET stable_id=\"$new_stable_id\", outcome=\"$outcome\", dataset_id=$dataset_id, gene_source=\"$geneSource\", gene_id=\"$geneId\", gene_name=\"$geneName\", gene_version=\"$geneVersion\", tf_source=\"$tfSource\", tf_id=\"$tfId\", tf_name=\"$tfName\", tf_version=\"$tfVersion\", loci_name=\"$lociName\", regulatory_sequence=\"$regulatory_sequence_id\", regulatory_sequence_with_flank=\"$regulatory_sequence_with_flank_id\", sequence_search_space=\"$sequence_search_space_id\", species_id=\"$speciesid\", reference_id=\"$referenceid\", entry_date=\"$formatted_date\", type=\"$type\", user_id=\"$userid\"";
   if ($write eq "TRUE"){
     my $sth2 = $dbh -> prepare($INSERT_INTO_RECORD_SQL) or die "Couldn't prepare statement: " . $dbh->errstr;
     $sth2->execute() or die "Couldn't execute statement: " . $sth2->errstr;
     if ($sth2->rows == 0 ){print "No record found\n";exit;}
     $sth2->finish;
   }
   if ($write eq "FALSE"){
     print "$INSERT_INTO_RECORD_SQL;\n\n";
   }

   #find the record id for the new record. If just checking SQL (i.e., update=FALSE, this will be set to ?)
   my $recordid;
   my $recordid_SQL = "SELECT id FROM record WHERE stable_id=\"$new_stable_id\"";
   if ($write eq "TRUE"){
     my $sth7 = $dbh->prepare($recordid_SQL) or die "Couldn't prepare statement: " . $dbh->errstr;
     $sth7->execute() or die "Couldn't execute statement: " . $sth7->errstr;
     if ($sth7->rows == 0) {print "No record found\n";exit;}
     my @data7;
     @data7 = $sth7->fetchrow_array();
     $recordid = $data7[0];
     $sth7->finish;
   }
   if ($write eq "FALSE"){
     $recordid="?";
     print "$recordid_SQL;\n\n";
   }

   #Insert evidence details into record_evidence table for the record
   my $evidenceSet = $record -> {evidenceSet}[0];
   my @evidence = @{$evidenceSet -> {evidence}};
   foreach my $evidence (@evidence){
     my $evidencecellType = $evidence -> {cellType}[0];
     my $evidencecomment = $evidence -> {comment}[0];
     #Remove any tabs or newlines from evidence comment
     $evidencecomment =~ s/\n//g ;
     $evidencecomment =~ s/\t//g ;
     my $quoted_evidencecomment = $dbh -> quote($evidencecomment);
     my $evidenceClassStableId = $evidence -> {evidenceClassStableId}[0];
     my $evidenceSubtypeStableId = $evidence -> {evidenceSubtypeStableId}[0];
     my $evidenceTypeStableId = $evidence -> {evidenceTypeStableId}[0];
     my $evidencetypeid = $evidencetype_ids{$evidenceTypeStableId};
     my $evidencesubtypeid = $evidencesubtype_ids{$evidenceSubtypeStableId};
     my $evidenceclassid = $evidenceclass_ids{$evidenceClassStableId};
     my $celltypeid="NULL";
     if($evidencecellType=~/EV\:\d+/){
       $celltypeid = $celltype_ids{$evidencecellType};
     }
     #inserting the evidence info into the record_evidence table
     my $INSERT_INTO_RECORD_EVIDENCE = "INSERT INTO record_evidence SET record_id=\"$recordid\", evidence_type_id=\"$evidencetypeid\", evidence_subtype_id=\"$evidencesubtypeid\", evidence_class=\"$evidenceclassid\", celltype_id=$celltypeid, evidence_comment=$quoted_evidencecomment, entry_date=\"$formatted_date\", user_id=\"$userid\"";
     if ($write eq "TRUE"){
       my $sth8 = $dbh-> prepare($INSERT_INTO_RECORD_EVIDENCE) or die "Couldn't prepare statement: " .$dbh->errstr;
       $sth8->execute() or die "Couldn't execute statemnet: " . $sth8->errstr;
       if ($sth8->rows ==0)
	 {
           print "No record found\n";
           exit;
	 }
       $sth8->finish;
     }
     if ($write eq "FALSE"){
       print "$INSERT_INTO_RECORD_EVIDENCE;\n\n";
     }
   }

   #Insert comments for record
   my $commentSet = $record -> {commentSet}[0];
   my @comments = @{$commentSet -> {comment}};
   foreach my $comment (@comments){
     my $comm = $comment -> {comment}[0];
     if ($comm){
       #Remove any tabs or newlines from comment
       $comm =~ s/\n//g;
       $comm =~ s/\t//g;
       my $quoted_comment = $dbh -> quote($comm);
       #inserting the record's comment into the comment table
       my $INSERT_INTO_COMMENT = "INSERT INTO comment SET comment=$quoted_comment, user_id=\"$userid\", entry_date=\"$formatted_date\", record_id=\"$recordid\"";
       if ($write eq "TRUE"){
	 my $sth9=$dbh->prepare($INSERT_INTO_COMMENT) or die "Couldn't prepare statement: " . $dbh->errstr;
	 $sth9->execute() or die "Couldn't execute statement: " . $sth9->errstr;
	 if ($sth9->rows == 0)
	   {
	     print "No record found\n";
	     exit;
	   }
	 $sth9->finish;
       }
       if ($write eq "FALSE"){
	 print "$INSERT_INTO_COMMENT;\n\n";
       }
     }
   }
}
exit;

sub insertSequence{
  my $sequence_ref = shift @_;

  my $sequence_id;
  my $sequence = $sequence_ref -> {sequence}[0];
  my $ensembl_database_name = $sequence_ref -> {ensembl_database_name}[0];
  my $strand = $sequence_ref -> {strand}[0];
  my $sequence_region_name = $sequence_ref -> {sequence_region_name}[0];
  my $verified = $sequence_ref -> {verified}[0];
  my $internalSequenceType = $sequence_ref -> {internalSequenceType}[0];
  my $start = $sequence_ref -> {start}[0];
  my $end =  $sequence_ref -> {end}[0];

  #insert the sequence info into the sequence table and then update the record table with the new sequence id.
  my $INSERT_INTO_SEQUENCE_SQL = "INSERT INTO sequence SET ensembl_database_name=\"$ensembl_database_name\", sequence_region_name=\"$sequence_region_name\", sequence=\"$sequence\", start=\"$start\", end=\"$end\", strand=$strand, verified=\"$verified\", sequence_type=\"$internalSequenceType\"";

  if ($write eq "TRUE"){
    my $sth_seq = $dbh-> prepare($INSERT_INTO_SEQUENCE_SQL) or die "Couldn't prepare statement: " .$dbh->errstr;
    $sth_seq->execute() or die "Couldn't execute statemnet: " . $sth_seq->errstr;
    if ($sth_seq->rows==0){print "No record found\n";exit;}
    $sth_seq->finish;

    #Obtain the new id for the sequence so that the record table can be updated.
    my $sth_lastid = $dbh->prepare("select last_insert_id() as id");
    $sth_lastid->execute or die "Couldn't execute statemnet: " . $sth_lastid->errstr;
    $sequence_id = $sth_lastid->fetchrow_hashref->{'id'};
    $sth_lastid->finish;
    unless($sequence_id){print "No sequence id returned from last insert id query\n"; exit;}
    if ($sequence_id==0){print "zero-value sequence id returned from last insert id query\n"; exit;}
  }
  if ($write eq "FALSE"){
    print "$INSERT_INTO_SEQUENCE_SQL;\n\n";
    $sequence_id="?";
  }
  return ($sequence_id);
}

sub printUsage{
  print "usage: addXML_to_OregannoDB.pl --file=xmlfile.xml --date=2008-09-12 --write=FALSE\n\n";
  print "options:\n--file (provide XML file to upload)\n";
  print "--write [FALSE/TRUE] (specifies whether inserts/updates should be performed)\n";
  print "--date (provide date to be used for all records, comments, and evidence comments [yyyy-mm-dd])\n";
  print "Warning: always run with --write=FALSE first and check SQL statements carefully\n";
  print "Note: when running with --write=FALSE, the record_id will be \"?\" because the new record has not yet been created\n";
  exit;
}
