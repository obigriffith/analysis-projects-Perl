#!/usr/local/bin/perl -w
#Determines avg quality and reads/clone for clones submitted during a certain
#time period.  Should normalize avg clone number for insert size at some point 
#Also counts problem clones during this period.
#

use DBI;
use strict;

my $startdate= "\'2002-08-28 00:00:00\'";
my $enddate= "\'2004-08-01 00:00:00\'";
my $dsn;
my $dbh;
my $total_readnumber=0;
my $total_quality=0;

dbConnect("sequence");
print "connected to sequence database\n";


#my $problemclones = getProblemCloneCount($startdate,$enddate);

my $submissionsref = getSubmissions($startdate,$enddate);
my @submissions = @$submissionsref;

#print "\n";
my $lengthOfQueryArray = @submissions;
    for(my $j = 0; $j < $lengthOfQueryArray; $j++){
      my $mgc = $submissions[$j][0];
      my $version = $submissions[$j][1];
      my $submissiondate = $submissions[$j][2];
      my ($readnumber,$quality)=getFinishedCloneInfo($mgc,$version);
      $total_readnumber = $total_readnumber + $readnumber;
      $total_quality = $total_quality + $quality;
      print "$mgc\t$version\t$readnumber\t$quality\t$submissiondate\n";

    }

my $count = $lengthOfQueryArray;
my $avg_readnumber = ($total_readnumber/$count);
my $avg_quality = ($total_quality/$count);


print "\nSummary for clones submitted between $startdate to $enddate\n";
print "Total clones submitted: $count\n";
print "Average Read Number per Clone: $avg_readnumber\n";
print "Average Clone Quality: $avg_quality\n";
#print "Total problem clones: $problemclones\n";

#foreach my $submission(@submissions){
#  print "$submission\n";
#}


exit;

sub getFinishedCloneInfo{
  my $mgc = shift;
  my $version = shift;
  my $query = "SELECT finishing.beta_Finished.Finished_Reads,finishing.beta_Finished.Finished_Quality FROM finishing.beta_Finished WHERE finishing.beta_Finished.Finished_MGC_Number=$mgc AND finishing.beta_Finished.Finished_Version=$version";
  my $queryArrayRef = evaluateQuery($query);
  my @queryArray = @$queryArrayRef;
  my $readnumber = $queryArray[0][0];
  my $quality = $queryArray[0][1];

  return ($readnumber, $quality);
}

sub getProblemCloneCount{
  my $startdate = shift;
  my $enddate = shift;
  my $query = "SELECT sequence.Clone.Clone_Source2_Name FROM sequence.Clone_History, sequence.Clone WHERE sequence.Clone_History.FK_Clone_Status__ID > 500 AND sequence.Clone_History.History_DateTime > $startdate AND sequence.Clone_History.History_DateTime < $enddate AND sequence.Clone.Clone_ID = sequence.Clone_History.FK_Clone__ID group by sequence.Clone.Clone_Source2_Name";
  my $queryArrayRef = evaluateQuery($query);
  my @queryArray = @$queryArrayRef;
  my $problemclonecount = @queryArray;
  return ($problemclonecount);
}

sub getSubmissions{
  my $startdate = shift;
  my $enddate = shift;
  my $query = "SELECT sequence.Clone.Clone_Source2_Name, MAX(finishing.beta_Finished.Finished_Version), sequence.Clone_History.History_DateTime FROM sequence.Clone_History, sequence.Clone, finishing.beta_Finished WHERE sequence.Clone_History.FK_Clone_Status__ID = 500 AND sequence.Clone_History.History_DateTime > $startdate AND sequence.Clone_History.History_DateTime < $enddate AND sequence.Clone.Clone_ID = sequence.Clone_History.FK_Clone__ID AND sequence.Clone.Clone_Source2_Name = finishing.beta_Finished.Finished_MGC_Number group by sequence.Clone.Clone_Source2_Name";

#  my $query = "SELECT Clone_Source2_Name FROM Clone_History, Clone WHERE Clone_History.FK_Clone_Status__ID = 500 AND History_DateTime >$startDate AND History_DateTime < $endDate AND Clone_ID = FK_Clone__ID group by Clone_Source2_Name";

  my $queryArrayRef = evaluateQuery($query);
  my @queryArray = @$queryArrayRef;
  return \@queryArray;
}

sub evaluateQuery {
  my $query = shift;
  my @queryTable;
  my $sth = $dbh -> prepare("$query");
  $sth -> execute();
  for(my $i = 0; my @array = $sth -> fetchrow_array(); $i++){
    my $lengthOfQueryArray = @array;
    for(my $j = 0; $j < $lengthOfQueryArray; $j++){
      $queryTable[$i][$j] = $array[$j];
    }
  }
  $sth -> finish();
  return(\@queryTable);
}

sub dbConnect{
my $database = shift;
  $dsn = "DBI:mysql:$database:seqdb01";
  $dbh = DBI -> connect($dsn, 'viewer', 'viewer', {RaiseError => 1});
}
