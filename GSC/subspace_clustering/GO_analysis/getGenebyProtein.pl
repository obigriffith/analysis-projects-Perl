#!/usr/local/bin/perl56 -w
#!/usr/bin/perl -w
#!/usr/local/bin/perl -w

use DBI;
use strict;
use Data::Dumper;
use Getopt::Std;
use lib "/home/obig/lib";
#use lib "/home/obig/lib/ensembl_32_perl_API/ensembl/modules";
use lib "/home/obig/lib/ensembl_35_perl_API/ensembl/modules";

use Bio::EnsEMBL::DBSQL::DBAdaptor;
#use Bio::SeqIO;

getopts("f:d:h:u:o:");
use vars qw($opt_f $opt_d $opt_h $opt_u $opt_o);

#my $user = 'ensembl';
my $password = 'ensembl';
#my $user = 'anonymous';
#my $host = 'db02';
#my $host = 'db01';
#my $host = 'kaka.sanger.ac.uk';
#my $dbname = 'homo_sapiens_core_27_35a';

my $dbname = $opt_d;
my $host= $opt_h;
my $user=$opt_u;
my $outfile=$opt_o;
my $infile = $opt_f;

my $db = new Bio::EnsEMBL::DBSQL::DBAdaptor(-host => $host,
					    -user => $user,
					    -dbname => $dbname,
					    -group => 'core',
					    -pass => $password);

#my $db = new Bio::EnsEMBL::DBSQL::DBAdaptor(-host => $host,
#					    -user => $user,
#					    -dbname => $dbname);


open (OUTFILE, ">$outfile") or die "can't open $outfile\n";
open (INFILE, $infile) or die "can't open $infile\n";

while (<INFILE>){
  my ($probe_id,$protein_id);
  if ($_=~/(\S+)\s+(\S+)/){
    $probe_id = $1;
    $protein_id = $2;
  }else{print "$_ not of expected format\n";next;}
  unless ($protein_id=~/ENSP\w+/){print "$protein_id of unexpected format\n";next;}
  my $gene_adaptor = $db->get_GeneAdaptor;
  my $gene = $gene_adaptor->fetch_by_translation_stable_id($protein_id);
  unless ($gene){print "Gene not found for \'$protein_id\'\n";next;}
  if ($gene->is_known) {
    my $gene_stable_id = $gene->stable_id;
    my $gene_name = $gene->external_name;
    print OUTFILE "$probe_id\t$protein_id\t$gene_stable_id\n";
  } else {
    print "Gene " . $gene->stable_id . " is not a known gene\n";
  }
}
close INFILE;
close OUTFILE;
exit;

