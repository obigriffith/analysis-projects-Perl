#!/usr/bin/perl -w

use DBI;
use strict;
use Data::Dumper;


unshift(@INC, "/home/malachig/perl/ensembl_35_perl_API/ensembl/modules");
use lib "/home/malachig/perl/bioperl-1.4";
require Bio::EnsEMBL::DBSQL::DBAdaptor; 
my $ensembl_api = 'Bio::EnsEMBL::Registry';
my $ensembl_server = "ensembl01.bcgsc.ca";
my $ensembl_user = "ensembl";
my $ensembl_password = "ensembl";
$ensembl_api ->load_registry_from_db(-host=>$ensembl_server, -user=>$ensembl_user, -pass=>$ensembl_password);


open (OUT, ">coordinate_comment.txt");
my $inputfile = 'ctgPos.txt';
open (INPUTFILEHANDLE, $inputfile);
my @INFO = <INPUTFILEHANDLE>;

my $host = "web02";
my $user_name = "oregano";
my $password = "IFjwqee";
my $db_name = "oregano";
my $socket_line = "";

#Establish a database connection. DBI returns a database handle object, which we store into $dbh.
my $dbh = DBI->connect("DBI:mysql:host=$host;database=$db_name" . $socket_line, $user_name, $password, {PrintError => 0,
RaiseError => 1}) || die("Cannot connect to ORegAnno MySQL database at $host");

my $record_id = "SELECT id,regulatory_sequence FROM record WHERE dataset_id=\"10\"";
my $sth1 = $dbh-> prepare($record_id) or die "Couldn't prepare statement: " . $dbh->errstr;
$sth1->execute() or die "Couldn't execute statement: " . $sth1->errstr;
if ($sth1->rows == 0)
{
    print "No record_id found\n";
    exit;
}
my @data1;
while (@data1 = $sth1->fetchrow_array())
{
    #print $data1[0], "\n";
    my $comment = "SELECT Comment,id FROM comment WHERE record_id=\"$data1[0]\"";
    my $sth2 = $dbh-> prepare($comment) or die "Couldn't prepare statement: " . $dbh->errstr;
    $sth2->execute() or die "Couldn't execute statement: " . $sth2->errstr;
    if ($sth2->rows == 0)
    {
	print "No comment found\n";
	exit;
    }
    my @data2;  
    my $i=0;
    while (@data2 = $sth2->fetchrow_array())
    {	
	if ($i % 2 != 0 )
	{
	    my @EX1 = split ("chr", $data2[0]);
	    my @EX2 = split (":", $EX1[1]);
	    my @EX3 = split ("-", $EX2[1]);
	    my $chr = $EX2[0];
	    my $start = $EX3[0]-1;
	    my $end = $EX3[1];
	    if ((($chr =~ m/(\d+)_random/) || ($chr =~ m/(\w+)_random/)) & ($start != "3803055") & ($end != "3803905"))
	    {	
		my @DATA;
		foreach my $info (@INFO)
		{
		    @DATA = split ("\t", $info);
		    {		
			if (("chr".$chr eq $DATA[2]) & ($start >= $DATA[3]) & ($end <= $DATA[4]))
			{
			    my $chr2 = "$1_$DATA[0]";
			    my $start2 = $start - $DATA[3];
			    my $end2 = $end - $DATA[3];
			    my $slice_adaptor = $ensembl_api->get_adaptor('Human', 'Core', 'Slice');
			    unless ($slice_adaptor)
			    {
				print "\nCould not get slice for this species - check EnsEMBL version, species, available databases on server, etc.\n\n";
				exit();
			    }
			    my $slice = $slice_adaptor->fetch_by_region('chromosome', $chr2, $start2, $end2,1);
			    #print $data1[1], "\n";
			    #print $chr2, "\t", $start2, "\t", $end2 , "\n";
			    my $sequence = $slice->seq();
			    print OUT "range=chr$chr:$start-$end\tEnsembl database: homo_sapiens_37_35j\n$sequence\n";

			    my $UPDATE_SEQUENCE = "UPDATE sequence SET sequence=\"$sequence\" WHERE id=\"$data1[1]\"";
			    print $UPDATE_SEQUENCE, "\n";
			    #my $sth3 = $dbh -> prepare($UPDATE_SEQUENCE) or die "Couldn't prepare statement: " . $dbh->errstr;
			    #$sth3->execute() or die "Couldn't execute statement: " . $sth3->errstr;
			    #if ($sth3->rows == 0 )
			    #{
			    #  print "No record found\n";
			    #  exit;
			    #}
			    #$sth3->finish;

			    my $UPDATE_COMMENT = "UPDATE comment SET Comment=\"range=chr$chr:$start-$end\tEnsembl database: homo_sapiens_37_35j\" WHERE id=\"$data2[1]\"";
			    print $UPDATE_COMMENT, "\n";
			    #my $sth4 = $dbh -> prepare($UPDATE_COMMENT) or die "Couldn't prepare statement: " . $dbh->errstr;
			    #$sth4->execute() or die "Couldn't execute statement: " . $sth4->errstr;
			    #if ($sth4->rows == 0 )
			    #{
			    #  print "No record found\n";
			    #  exit;
			    #}
			    #$sth4->finish;
			}
		    }
		}
	    }
	    elsif ((($chr =~ m/(\d+)/) || ($chr =~ m/(\w+)/)) & ($start != "3803055") & ($end != "3803905"))
	    {
		my $slice_adaptor = $ensembl_api->get_adaptor('Human', 'Core', 'Slice');
		unless ($slice_adaptor)
		{
		    print "\nCould not get slice for this species - check EnsEMBL version, species, available databases on server, etc.\n\n";
		    exit();
		}
		my $slice = $slice_adaptor->fetch_by_region('chromosome', $chr, $start, $end,1);
		#print $data1[1], "\n";
		#print $chr, "\t", $start, "\t", $end , "\n";
		my $sequence = $slice->seq();
		print OUT "range=chr$chr:$start-$end\tEnsembl database: homo_sapiens_37_35j\n$sequence\n";

		my $UPDATE_SEQUENCE = "UPDATE sequence SET sequence=\"$sequence\" WHERE id=\"$data1[1]\"";
		print $UPDATE_SEQUENCE, "\n";
		#my $sth5 = $dbh -> prepare($UPDATE_SEQUENCE) or die "Couldn't prepare statement: " . $dbh->errstr;
		#$sth5->execute() or die "Couldn't execute statement: " . $sth3->errstr;
		#if ($sth5->rows == 0 )
		#{
		#  print "No record found\n";
		#  exit;
		#}
		#$sth5->finish;

		my $UPDATE_COMMENT = "UPDATE comment SET Comment=\"range=chr$chr:$start-$end\tEnsembl database: homo_sapiens_37_35j\" WHERE id=\"$data2[1]\"";
		print $UPDATE_COMMENT, "\n";
		#my $sth6 = $dbh -> prepare($UPDATE_COMMENT) or die "Couldn't prepare statement: " . $dbh->errstr;
		#$sth6->execute() or die "Couldn't execute statement: " . $sth6->errstr;
		#if ($sth6->rows == 0 )
		#{
		#  print "No record found\n";
		#  exit;
		#}
		#$sth6->finish;
	    }
	}
	$i++;
    }
    $sth2->finish;
}
$sth1->finish;

exit;
