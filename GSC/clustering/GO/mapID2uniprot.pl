#!/usr/local/bin/perl -w

use strict;
use Getopt::Std;
use constant DEBUG 		=> 0;
getopts("f:o:t:");
use vars qw($opt_o $opt_f $opt_t);

my $infile = $opt_f;
my $outfile = $opt_o;
my $id_type = $opt_t;

my $xrefs = "/home/obig/clustering/GO/GO_source/xrefs.goa";
my $uniprot_col = 1;
my $id_col;
my %uniprot_by_id;

#Currently only set up for LL or HUGO.  Other IDS (eg. ENSP) are available in xrefs.goa.  If you add this functionality be careful of multiple entries for one uniprot
#Note xrefs.goa file has HUGO in column 9 and Locus in column 10
if ($id_type eq 'LocusLink'){$id_col=9;}
if ($id_type eq 'HUGO'){$id_col=8;}

#Create hash mapping specified ID type to uniprot
&Build_ID_XREF();

#now look for mapping for IDs in file of interest
open (INFILE, $infile) or die "can't open $infile\n";
open (OUTFILE, ">$outfile") or die "can't open $outfile\n";

while (<INFILE>){
  my $id = $_;
  chomp $id;
  print "id->$id\n" if DEBUG;
  my $uniprot_id = &Conv2Uniprotid($id);
  print "uniprot_id->$uniprot_id\n" if DEBUG;
  unless ($uniprot_id eq 'NA'){
    print OUTFILE "$id\t$uniprot_id\n";
  }
}
close INFILE;
close OUTFILE;
exit;

#-------------------------------------------------------------------------------------------
# Converts Uniprot id to Locuslink id
sub Conv2Uniprotid () {
  my $id = shift;

  if ($uniprot_by_id{$id}) {
    return $uniprot_by_id{$id};
  }
  else {
    print "uniprot_id for id : $id not found\n" if DEBUG;
    return "NA";
  }
}

#-------------------------------------------------------------------------------------------------------
#Builds the ID hash using EBI human xref file
#URL: ftp://ftp.ebi.ac.uk/pub/databases/GO/goa/HUMAN/
sub Build_ID_XREF {

  open (XREFS, $xrefs) || die "Can't open file:$!\n";

  while (<XREFS>) {
    chomp $_;
    my @fields = split (/\t/, $_);

    if ($fields[$id_col]){
      my @IDs = split(/,/, $fields[$id_col]);
      if ($IDs[0]) {
	#If using LocusLink this column contains two values: LocusLink Number, LocusLink Gene Symbol - usually we want the Number therefore use $IDs[0]
	#If using HUGO this column contains two values: HUGO HGNC number, HUGO Gene Symbol - usually we want the Symbol therefore use $IDs[1]
	if ($id_type eq 'LocusLink'){$uniprot_by_id{$IDs[0]} =  $fields[$uniprot_col];}
	if ($id_type eq 'HUGO'){$uniprot_by_id{$IDs[1]} =  $fields[$uniprot_col];}
      }
    }
  }

  print "locus link hash table built ... \n" if DEBUG;
  close(XREFS);

}
