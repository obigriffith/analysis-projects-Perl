#!/usr/bin/perl

use strict;

my $access_log = @ARGV[0];
if (!defined($access_log)) { die("No access log defined"); }
unless (-f $access_log) { die("Access log does not exist: " . $access_log);}
open (ACC, $access_log) || die("Cannot open access log");
my %ADDRESSES;
my $i = 0;
while (my $line = <ACC>) {
	chomp($line);
	if ($line =~ /([\S]+)[\s]+[\S\s]+/g) {
		my $address = $1;
		if (!defined($ADDRESSES{$address})) {
			$ADDRESSES{$address} = $i++;
		}
	}
}

my $count = 0;
foreach my $key (sort {$ADDRESSES{$a} <=> $ADDRESSES{$b}} keys %ADDRESSES) {
	print $key . "\n";
	$count++;
}
print "COUNT: " . $count . "\n";
close(ACC);
exit(0);

