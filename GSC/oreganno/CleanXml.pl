#!/usr/bin/perl -w

use strict;

#The following script takes an oreganno dump file (consisting of multiple separate xml files concatenated) and converts it to a single proper xml file.
#usage: CleanXml.pl cron.saved.24-Jul-2006.xml > cron.saved.24-Jul-2006.clean.xml

#Change input record separator. When you undef $/ you can read in a whole, multi-line file into a single string
undef $/;

#Print standard xml header and high-level oreganno tags
print "<?xml version=\"1.0\" encoding=\"ISO-8859-1\"?>\n<oreganno>\n<recordSet>\n";

#Load all oreganno xml data into file
my $oreganno_data=<>;

#Find each oreganno record (i.e. everything within <record> and </record> tag pairs
while($oreganno_data=~/(\<record\>.+?\<\/record\>)/sg){print "$1\n";};

#Print closing high-level tags
print "</recordSet>\n</oreganno>\n";

