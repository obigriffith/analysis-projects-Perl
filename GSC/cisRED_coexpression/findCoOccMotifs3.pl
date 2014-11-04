#!/usr/bin/perl
#
#    calcCoOcc
#
#    Asim Siddiqui 2005
#
#    calc co-occurrence values given motifs in the database.
#    uses a method similar to Zhu et al (2005)

use DBI;
use Getopt::Std;
$| = 1;

getopts("d:w:l:o:",\%options);

if (!defined($options{d}) || !defined($options{l}) || !defined($options{w}) || !defined($options{o}))
{
    print "USAGE: cmd -d database -w window -l promoterLength -o outputFilebase\n";
    exit;
}

#-----DATABASE CONNECTION-----------------
my $server = "db01";
my $user_name = "viewer";
my $password = "viewer";

my $db_name = $options{d};
my $dsn = "DBI:mysql:$db_name:$server";
#------------------------------------------

my $dbh = DBI->connect($dsn,$user_name,$password,{PrintError=>1}) || die;

$WINDOW = $options{w};
$LENGTH = $options{l};
$outputFileBase = $options{o};

# get all clusters
print "Reading clusters...\n";
#$sth = $dbh->prepare( " SELECT accession_id,feature_id FROM accession" ) || die "error in pop table";
#Note, a schema change from cisred_1_2e means that group_id replaces accession id (group_content table replaces accession table)
$sth = $dbh->prepare( "SELECT group_id, feature_id FROM group_content where group_id>0;" ) || die "error in pop table";
$sth->execute() || die "error in pop table";
while ( my @row = $sth->fetchrow_array() )
{
    $accession_id = $row[0];
    $feature_id = $row[1];
    $fIdToAccId{"$feature_id"} = $accession_id;
    $accessionCounts{"$accession_id"} += 1;
    $fIdsForAcc{"$accession_id"} .= "$feature_id ";
#    print "$accession_id $feature_id\n";
}

# get all features
print "Reading features...\n";
$sth = $dbh->prepare( " SELECT f.id,sequence,source_annotation,source_start,f.score FROM sitesequences s, features f where  f.id=s.feature_id and f.ensembl_gene_id=s.source_annotation " ) || die "error in pop table";
$sth->execute() || die "error in pop table";
while ( my @row = $sth->fetchrow_array() )
{
    $id = $row[0];
    $seq = $row[1];
    $gene = $row[2];
    $start = $row[3];
    $score = $row[4];
    $fIdToTargetGene{"$id"} = $gene;
    $fIdToStart{"$id"} = $start;
    $fIdToScore{"$id"} = $score;
    $fIdsForGene{"$gene"} .= "$id ";
    $countGenes{"$gene"} = 1;
}

$sth->finish();
$dbh->disconnect();

@countGeneKeys = keys %countGenes;
$totalNumGenes = $#countGeneKeys + 1;

print "Preprocessing data...\n";
foreach $mc1 (keys %fIdsForAcc)
{
    undef %countGenes;
    $count = 0;
    @ids = split(" ", $fIdsForAcc{"$mc1"});
    foreach $id (@ids)
    {
        $gene = $fIdToTargetGene{"$id"};
        if (!defined($countGenes{"$gene"}))
        {
            $count++;
            $countGenes{"$gene"} = 1;
        }
    }
    $accessionGeneCounts{"$mc1"} = $count;
}

print "Scoring data...\n";
open( COOCC, ">$outputFileBase.coocc");
@mcKeys = keys %fIdsForAcc;

$c1 = 0;

while ($c1 < ($#mcKeys + 1))
{
    $mc1 = $mcKeys[$c1];
    if ( $c1 % (($#mcKeys + 1) / 20 ) == 0 )
    {
        $perComplete = ($c1 * 5) / (($#mcKeys + 1) / 20);
        print "$perComplete complete\n";
    }
    if ( $accessionCounts{"$mc1"} < 2 )
    {
        $c1++;
        next;
    }
    @firstIds = split(" ", $fIdsForAcc{"$mc1"});

    $c2 = $c1;
    while ($c2 < ($#mcKeys + 1))
    {
        $mc2 = $mcKeys[$c2];
        if ( $accessionCounts{"$mc2"} < 2 )
        {
            $c2++;
            next;
        }

# calc prob that a randomly sampled promoter region has the pair
        $prob = ( $accessionGeneCounts{"$mc2"} / $totalNumGenes ) *
                ($WINDOW / $LENGTH) *
                ( $accessionCounts{"$mc1"} / $accessionGeneCounts{"$mc1"} ) *
                ( $accessionCounts{"$mc2"} / $accessionGeneCounts{"$mc2"} );

# count the number of times that the second motif occurs within WINDOW bp of the first
        $occ = 0;
        @secondIds = split(" ", $fIdsForAcc{"$mc2"});

        undef %foundDefs;
        foreach $fId (@firstIds)
        {
            foreach $sId (@secondIds)
            {
                if ($fIdToTargetGene{"$fId"} eq $fIdToTargetGene{"$sId"} &&
                    abs( $fIdToStart{"$fId"} - $fIdToStart{"$sId"} ) < $WINDOW &&
                    !defined( $foundDefs{"$fId-$sId"}) &&
                    $fId ne $sId )
                {
                    $occ++;
                }
                    $foundDefs{"$fId-$sId"} = 1;
                    $foundDefs{"$sId-$fId"} = 1;
            }
        }


        if ($occ < 2 )
        {
            $c2++;
            next;
        }

        $ii = $occ;
        $p1 = 0;
        while ($ii <= $accessionGeneCounts{"$mc1"} )
        {
            $pTmp = ($prob ** $ii) * ( ( 1 - $prob) ** ( $accessionGeneCounts{"$mc1"} - $ii ));

            $botStop = $ii;
            $jj = $accessionGeneCounts{"$mc1"} - $ii;
            $topStop = $jj;
            if ($jj < $ii)
            {
                $topStop = $ii;
                $botStop = $jj;
            }
 
            $comb = 1;
            $kk = 1;
            while ( $kk <= $botStop )
            {
                $comb = $comb / ($kk );
                $kk++;
            }

            $kk = $accessionGeneCounts{"$mc1"};
            while ( $kk > $topStop )
            {
                $comb = $comb * $kk;
                $kk--;
            }
            
            $pTmp = $pTmp * $comb;
            $p1 += $pTmp;
            $ii++;
        }

#        print COOCC "$mc1 $mc2 $p1 $occ\n";

        undef %foundDefs;
        foreach $fId (@firstIds)
        {
            foreach $sId (@secondIds)
            {
	        #Skip cases where fID and sID are actually the same.
	        if ($fId==$sId){next;}
                if ($fIdToTargetGene{"$fId"} eq $fIdToTargetGene{"$sId"} &&
                    abs( $fIdToStart{"$fId"} - $fIdToStart{"$sId"} ) < $WINDOW &&
                    !defined( $foundDefs{"$fId-$sId"}))
                {
#		  print COOCC "$module_count\t$mc1\t$mc2\t$fId\t$sId\t$fIdToTargetGene{$fId}\t$fIdToTargetGene{$sId}\t$occ\t$p1\n";
		  print COOCC "$mc1\t$mc2\t$fId\t$sId\t$fIdToTargetGene{$fId}\t$fIdToTargetGene{$sId}\t$occ\t$p1\n";


#                    print $fIdToScore{"$fId"} . " $p1 $fId $sId HERE!\n";
                    $fIdToScore{"$fId"} *= $p1;
                    if ( $fId ne $sId )
                    {
                        $fIdToScore{"$sId"} *= $p1;
                    }
                    $foundDefs{"$fId-$sId"} = 1;
                    $foundDefs{"$sId-$fId"} = 1;
#                    print $fIdToScore{"$fId"} . " $p1 $fId $sId HERE2!\n";
                    
                }
            }
        }

        $c2++;
    }

    $c1++;
}

close COOCC;

open( NEWPROBS, ">$outputFileBase.newPval");
foreach $id (keys %fIdToScore)
{
    print NEWPROBS "$id " . $fIdToScore{"$id"} . "\n";
}

close NEWPROBS;
