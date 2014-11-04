#!/usr/bin/perl -w
#!/usr/local/bin/perl56 -w
#!/usr/local/bin/perl -w

use DBI;
use strict;
use Data::Dumper;
use Getopt::Std;
use lib "/home/obig/lib";
use lib "/home/obig/lib/ensembl_27_perl_API/ensembl/modules";
use Bio::EnsEMBL::DBSQL::DBAdaptor;
#use Bio::SeqIO;

getopts("f:d:h:u:");
use vars qw($opt_f $opt_d $opt_h $opt_u);

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

my $db = new Bio::EnsEMBL::DBSQL::DBAdaptor(-host => $host,
					    -user => $user,
					    -dbname => $dbname,
					    -pass => $password);

#my $db = new Bio::EnsEMBL::DBSQL::DBAdaptor(-host => $host,
#					    -user => $user,
#					    -dbname => $dbname);

my $infile = $opt_f;

open (INFILE, $infile) or die "can't open $infile\n";

while (<INFILE>){
  my ($probe_id,$transcript_id);
  if ($_=~/(\S+)\s+(\S+)/){
    $probe_id = $1;
    $transcript_id = $2;
  }
  unless ($transcript_id=~/[ENST\ENSMUST]\w+/){next;}
  my $gene_adaptor = $db->get_GeneAdaptor;
#  print "looking for: $transcript_id\n";
  my $gene = $gene_adaptor->fetch_by_transcript_stable_id($transcript_id);
  unless ($gene){print "Gene not found for \'$transcript_id\'\n";next;}
  if ($gene->is_known) {
    my $gene_stable_id = $gene->stable_id;
    my $gene_name = $gene->external_name;
    print "$probe_id\t$transcript_id\t$gene_stable_id\n";
  } #else {
#    print "Gene " . $gene->stable_id . " is not a known gene\n";
#  }
}
exit;

