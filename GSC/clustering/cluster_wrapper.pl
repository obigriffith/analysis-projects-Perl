#!/usr/bin/perl

use Getopt::Std;
use Data::Dumper;
use DBI;
use strict;

getopts("nzhf:t:o:");
use vars qw($opt_n $opt_f $opt_t $opt_o $opt_z $opt_h);
#if opt_n is not specified parse the file to be clustered to get the IDS and then run this program 
#with the opt_n switch 

#connect to database
my $dbname = "sage_library_comparisons_01";
my $dbh = DBI->connect( 'dbi:mysql:database=' . $dbname . ';host=db01', 'viewer', 'viewer', { PrintError => 1, RaiseError => 0 } );
my $cluster = "cluster.pl";

#if (!$opt_f or $opt_h){
#  &printDocs;
#}

if (! $opt_t){$opt_t = 0;} #use 0 for default threshold so that all results are printed.

#What are we going to do with the output?  This will be millions of files.  Maybe have to put it straight into a database?
#Or, maybe output won't be that big as long as a stringent threshold is used (eg. r=0.9)
my $outfile;
if ($opt_o){
  $outfile = $opt_o;
}

#Get total number of tags in database to be compared for coexpression
my $SQL1 = "select MAX(FK_tag_id) from tag_lib_comp";
my $sth1 = $dbh->prepare($SQL1);
$sth1->execute();
my $tag_count = $sth1->fetchrow_array();
$sth1->finish();

for my $tag1 (1..$tag_count) {
  my $tagname1 = &getTagName($tag1);
  for my $tag2 ($tag1+1..$tag_count) {
    my $tagname2 = &getTagName($tag2);
    open(OUTPUT,"$cluster $tag1 $tag2 |");
    if ($opt_o){open(OUTFILE, ">$outfile") or die "can't print to $outfile";}
    while (<OUTPUT>) {
      if (/^DISTANCE\s+(\d+)\s+(\d+)\s+(\S+)/ && ($3 >= $opt_t || $3 <= -$opt_t)) { #changed so that -ve and +ve correlations are considered.
	print "$tagname1\t$tagname2\t$3\n";
	if($opt_o){print OUTFILE "$tagname1\t$tagname2\t$3\n";}
	#remember to print out both relationships for the database table.
	print "$tagname2\t$tagname1\t$3\n";
	if($opt_o){print OUTFILE "$tagname2\t$tagname1\t$3\n";}
      }
    }
    close OUTPUT;
    $dbh->disconnect();
    if ($opt_o){close OUTFILE;}
  }
}


sub printDocs{
print "This script performs hierarchical clustering using pearson correlation as a distance metric
A tab delimited file with genes for rows and experiments for columns is required as input.
The first row is assumed to contain experiment headings and the first column, gene identifiers.

flags:
-n runs script without parsing data file for IDS or printing summary of coexpressed genes
-z normalize data before clustering (optional)

options:
-f input file containing tab delimited data (required)
-t pearson correlation threshold (default 0)
-o output file (optional)
";
exit;
}

sub getTagName{
my $tag_id = shift @_;
my $SQL = "select tag_name from tag where tag_id=$tag_id";
my $sth = $dbh->prepare($SQL);
$sth->execute();
my $tag_name = $sth->fetchrow_array();
$sth->finish();

return($tag_name);
}
