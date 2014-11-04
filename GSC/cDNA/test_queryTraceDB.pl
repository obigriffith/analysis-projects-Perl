#!/usr/bin/perl -w
use strict;
use LWP::UserAgent;
use HTTP::Request::Common 'POST';


my $accession = "BU961497";
my $query1 = "query text ACCESSION='$accession' > temp.txt";
my $command = "queryTraceDB.pl $query1";


system($command);

exit;

