#!/usr/local/bin/perl -w
#This script sets up a BLAT server for an entire genome.  Currently only Human and Mouse are available.
use strict;

#my $humandir = "/home/obig/perl/BLAT/golden_path_temp/*.nib";
my $humandir = "/home/pubseq/databases/H_sapiens_genome/golden_path/*.nib";
my $mousedir = "/home/pubseq/databases/M_musculus_genome/golden_path/*.nib";
my $genomedir;
printDocumentation();

print "proceed?\(y\)\n";
my $answer = <STDIN>;
chomp $answer;
unless($answer eq 'y'){
  exit;
}
print "Enter file to Blat for chimerism.  Must be in fasta format:\n";
my $file = <STDIN>;
chomp $file;
my $blatfile = "$file" . "\.blat";

print "Enter node: \(eg. 6of3\)\n";
my $node=<STDIN>;
chomp $node;

print "Human or Mouse BLAT? \(h or m\)\n";
my $answer2 = <STDIN>;
chomp $answer2;
if ($answer2 eq 'h'){
  $genomedir = $humandir;
}elsif ($answer2 eq 'm'){
  $genomedir = $mousedir;
}else{
  print "Invalid selection\n";
  exit;
}

my $command = "gfServer start $node 8051 $genomedir";

print "Setting up server.  Please wait...\n";
print "If very slow \(> 5-10min\), kill script and try another node.\n";

#Start Blat server
open(BLAT, "| $command");

#Check status periodically to determine when server is ready for queries.
while(1) {
  my $status = `gfServer status $node 8051 2>/dev/null`;
  last if ($status);
  sleep 5;
}

#Query the gfServer with gfClient
print "running gfClient to query server.  PLease wait...\n";
my $query = "gfClient $node 8051 / $file $blatfile";
system($query);
print "Blat complete\n";
killServerAndExit();
exit;


######################################################################################################
#killServerandExit
#Kills current gfServer
######################################################################################################
sub killServerAndExit{

my $killcommand = "gfServer stop $node 8051";
    system($killcommand);
print "gfServer stopped\n";
close BLAT;
exit;
}


####################################################################################
#Alternate method of killing gfServers.  Warning! kills all users gfServer processes
####################################################################################
#my $pid;
#my $ps = `ps | grep gfServer`;
#my @ps = split /\n/,$ps;
#print "Attempting to kill gfServer\n";
#foreach my $line(@ps){
#  if ($line =~ /^\s+(\d+)\s+\w+.+/){
#    $pid = $1;
#    print "killing process: $line\n";
#    `kill $pid`;
#  }
#}

###############################################################################
#Documentation
###############################################################################
sub printDocumentation{
print "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++\n";
print "This script sets up a BLAT server using gfServer that can then be queried with gfClient\n";
print "It is recommended that you log into a node before running this script\n";
print "For most accurate results update genome:\n";
print "Download latest chromFa.zip from http://genome.ucsc.edu/\n";
print "Extract chromosome files into the golden_path directory:\n";
print "/home/pubseq/databases/H_sapiens_genome/golden_path\n";
print "run FatoNibOnAllFiles.pl from this directory\n";
print "If the genome is up to date proceed with this script\n";
print "The server may take a while to come online.  If > 5 or 10 min kill and\n";
print "try another node\n";
print "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++\n";
}
