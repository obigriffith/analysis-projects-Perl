#!/usr/local/bin/perl -w


#take list of AFFY files and produce a single file for clustering analysis?
use strict;
use Getopt::Std;
use Data::Dumper;
use lib "/home/obig/bin/Cluster/Algorithm-Cluster-1.22/Statistics-Descriptive-2.6";
use Statistics::Descriptive;

getopts("f:o:t:ln");
use vars qw($opt_f $opt_o $opt_l $opt_n $opt_t);

unless ($opt_f){
  &printDocs;
}

my (%Data, %Detect, %Exp, %Inv_Data, %stats);
my ($dir, $outfile, $gene_count, $threshold);
my $filecount=0;
my $listfile = $opt_f;
if ($opt_o){$outfile=$opt_o;}
if ($opt_t){$threshold=$opt_t}else{$threshold=1;}

print "\nThis script will attempt to process a list of AFFY files provided into \na single datafile for clustering analysis, with experiments across the columns and genes along the rows\n\n";

if ($opt_o){open (OUTFILE, ">$outfile") or die "can't open $outfile for write\n";}

#First get list of experiment files.  Filenames will be used to refer to each experiment.
open (LISTFILE, $listfile) or die "can't open $listfile\n";
while (<LISTFILE>){
  my $file = $_;
  chomp $file;
  #Extract values from each file and add to %Data
  $gene_count=&processfile($file);
  $filecount++;
  print "$filecount: $file ($gene_count genes found)\n";
  #store experiment list in a hash
}
close LISTFILE;

#If specified, convert values to natural log
if ($opt_l){
  &logData();
}

#If specified, normalize values
if ($opt_n){
  &normalizeData();
}

#Create output file with all data.
if ($opt_o){
  #First print experiments across top of file
  print OUTFILE "Gene";
  foreach my $experiment (sort keys %Exp){
    print OUTFILE "\t$experiment";
  }
  print OUTFILE "\n";
  #Then fill in data for each gene
  foreach my $probe (sort keys %Data){
    print OUTFILE "$probe";
    foreach my $exp (sort keys %{$Data{$probe}}){
      if ($Data{$probe}{$exp}{'signal'} && $Data{$probe}{$exp}{'pvalue'}<=$threshold){ #If p-value meets specified threshold and a value exists
	print OUTFILE "\t$Data{$probe}{$exp}{'signal'}"; #print the value
      }else{ #otherwise leave blank
	print OUTFILE "\t";
      }
    }
    print OUTFILE "\n";
  }
  close OUTFILE;
}


sub processfile{
my $file = shift @_;
my %headings;
my $gene_count=0;
my $experiment;
#Parse experiment name from full path filename (expected format /path/to/filename.csv)
if ($file=~/.+\/(\S+)\.csv$/){
  $experiment = $1;
  $Exp{$experiment}++;
}else{
  print "file name of unexpected format: $file\n";
}

open (FILE, $file) or die "can't open $file\n";

#First determine where probe__id, intensity, and call can be found
my $header = <FILE>;
my $processed_header = &processLine($header);
my @headings = split (",", $processed_header, -1);
my $count = 0;
foreach my $heading (@headings){  #Finds each "entry" in the csv file.
  ++$count;
  $headings{$heading}=$count;
}

#Assumes columns will be named a certain way
my ($probe_id_col, $detect_col, $signal_col, $pvalue_col);
$probe_id_col = $headings{"Probe Name"};
unless ($probe_id_col){$probe_id_col = $headings{"ProbeName"};} #Some experiments are missing a space
$detect_col = $headings{"Detection Call"};
$signal_col = $headings{"Signal"};
$pvalue_col = $headings{"Detection P Value"};
#print "probeID (col: $probe_id_col)\tDetect (col: $detect_col)\tSignal (col:$signal_col)\tP-value (col:$pvalue_col)\n";

while (<FILE>){
  my $line = $_;
  my $processed_line = &processLine($line);
  my ($probe_id, $detect, $signal, $pvalue);
  my @entries = split (",", $processed_line, -1);
  $probe_id = $entries[$probe_id_col-1];
  $detect = $entries[$detect_col-1];
  $signal = $entries[$signal_col-1];
  $pvalue = $entries[$pvalue_col-1];
  #Check for AFFY controls and skip
  if ($probe_id=~/AFFX/){next;}
  #Create a HoH with all genes and their intensity values for each experiment
#  print "$experiment\t$probe_id\t$signal\t$detect\t$pvalue\n";
#  $Inv_Data{$experiment}{$probe_id}=$signal;
  $Data{$probe_id}{$experiment}{'signal'}=$signal;
  $Data{$probe_id}{$experiment}{'detect'}=$detect;
  $Data{$probe_id}{$experiment}{'pvalue'}=$pvalue;
  $gene_count++;
  }
close FILE;
return ($gene_count);
}

sub processLine{
  #This processing is necessary because csv files are not consistent.  Sometimes all entries are surrounded by quotes
  #Sometimes only certain entries are surrounded by quotes.  If entries are surrounded by quotes they can contain commas.
  #Thus, separating by quotes or commas is problematic.  So, first I remove commas and superfluous spaces from entries surrounded by quotes
  #Then, I remove all quotes so that entries can be split on commas easily.
  my $line = shift @_;
  #print "$line\n";
  while ($line =~ /(\".*?\")/g){ #find entries between ""
    my $entry = $1;
    if ($entry=~/\,/){ #If entry contains commas, remove them
      my $newentry=$entry;
      $newentry=~s/\,//g;
      $line=~s/\Q$entry\E/$newentry/; #replace original entry with new one that does not contain commas
    }
  }
  $line=~s/\s+\"/\"/g; #remove spaces in front of quotes
  $line=~s/\"\s+/\"/g; #remove spaces after quotes
  $line=~s/\"//g; #remove quotes
  #print "$line\n\n";
  chomp $line;
  return($line);
}

sub logData{
#Go through %Data and convert values to log
  foreach my $probe (keys %Data){
    foreach my $experiment (keys %{$Data{$probe}}){
      my $data = $Data{$probe}{$experiment}{'signal'};
      if ($data==0){$data = 1; print "$experiment: $probe: 0 converted to 1 for logging\n";}
      my $ln_signal = log($data);
      $Data{$probe}{$experiment}{'signal'}=$ln_signal;
    }
  }
}

sub normalizeData{
  print "Normalizing data by subtraction of median and then division by interquartile range for each experiment set\n";
  #For each column (ie. experiment) determine the median and interquartile range and size
  print "Determining median and interquartile ranges for experiments\n";
  foreach my $experiment (keys %Exp){
    my @vector;
    foreach my $probe (keys %Data){
      push (@vector, $Data{$probe}{$experiment}{'signal'}); #create a vector for all the gene values for this experiment
    }
    my $stat = Statistics::Descriptive::Full->new();
    $stat->add_data(\@vector);
    my $quartile_1st = $stat->percentile(25);
    my $quartile_3rd = $stat->percentile(75);
    my $median = $stat->median();
    my $interquartile = $quartile_3rd - $quartile_1st;
    #print "$experiment\t$median\t$interquartile\n";
    $stats{$experiment}{'median'}=$median;
    $stats{$experiment}{'interquartile'}=$interquartile;
  }
  #Next, create a new Data hash with normalized values ((value - median)/interquartile range)
  print "Normalizing data by subtraction of median and then division by interquartile range\n";
  foreach my $probe (sort keys %Data){
    foreach my $experiment (sort keys %{$Data{$probe}}){
      my $normal_data = ($Data{$probe}{$experiment}{'signal'} - $stats{$experiment}{'median'})/$stats{$experiment}{'interquartile'};
      $Data{$probe}{$experiment}{'signal'}=$normal_data;
    }
  }
}

sub printDocs{
print "Must supply a file containing the list of files to assemble into one data set\n";
print "Options:\n";
print "-f filename.txt\n";
print "-o outfile.txt\n";
print "-t threshold (used to specify p-value cutoff required to include value in output, default = 1)\n";
print "-l (flag to specify natural log of intensity instead of raw value)\n";
print "-n (flag to specify values should be normalized by subtracting median and dividing by interquartile range\n";
exit;
}
