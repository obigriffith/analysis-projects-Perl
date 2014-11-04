#!/usr/local/bin/perl -w
use strict;

#my $outfile = "stderr_and_out.txt";
#open (OUTFILE,">$outfile");

my $humandir = "/home/obig/perl/BLAT/golden_path_temp/*.nib";

my $command = "gfServer start 8of0 8051 $humandir";

open(PH, "|$command");

while(1) {
  print "Checking server status...\n";
  my $status = `gfServer status 8of0 8051`;
  print "status:$status\n";
  last if ($status);
  sleep 10;
}

#while (<PH>) {
#print OUTFILE $_;
#}

my $killcommand = "gfServer stop 8of0 8051";
    system($killcommand);
print "gfServer stopped\n";

close PH;
#close OUTFILE;
exit;


