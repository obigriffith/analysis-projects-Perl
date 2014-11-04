#!/usr/local/bin/perl -w
#
#This script searches a list of clones against all the primers ordered and returns
#an array of clones from the list given which have had one or more primer ordered

use strict;
my $primerfile = "/mnt/disk7/MGC/oligos/primer";

print "\nThis script will determine which clones from a given list have had primers ordered";
print "\nEnter the file containing the list of clones:  ";
my $clonefile = <STDIN>;
chomp $clonefile;

print "\nEnter name of outputfile:  ";
my $outfile = <STDIN>;
chomp $outfile;
open (OUTFILE, ">$outfile")or die "Can't open $outfile to output to";
print OUTFILE $outfile,"\n";
my @primerlist = makePrimerList($primerfile);
my @clonelist = makeCloneList($clonefile);


print "\n-----------PRIMER-LIST--------------\n";
print "@primerlist";
print "\n------------------------------------\n";

print "\n----------CLONE-LIST---------------\n";
print "@clonelist";
print OUTFILE "\nClones with PolyA regions:\n@clonelist";
print "\n------------------------------------\n";


my $clone;
my $primer;
my @NewClonelist = ();

foreach $clone(@clonelist){
#  print "\nClone:  $clone";
  foreach $primer(@primerlist){
#    print "\nPrimer:  $primer";
    if ($clone == $primer){
      push (@NewClonelist, $clone);
    }
  }
}

print "\n-----------NEW-CLONE-LIST--------------\n";
print "@NewClonelist";
print OUTFILE "\nClones with polyA regions for which clones were ordered:\n@NewClonelist";
print "\n---------------------------------------\n";

close OUTFILE;
exit;


##################################################################
#make a an array containing all the primers that have been ordered
##################################################################
sub makePrimerList{

my($primerfilename) = @_;

open (PRIMER,$primerfilename) or die "Can't open $primerfile file";
my @primers = <PRIMER>;
close PRIMER;

my @primers2 = ();

#remove everything except for the clone numbers for which primers were ordered
foreach my $primer(@primers){
  if ($primer =~ s/^(\d+).*/$1/){
    push( @primers2, $1 );
  }
}
#print "\n-------------------------\n";
#print "@primers2";
#print "\n-------------------------\n";

return @primers2;
}

###################################################################
#make a an array containing all the cloness that have polyA regions
###################################################################
sub makeCloneList{

my($clonefilename) = @_;

open (CLONES, $clonefilename) or die "Can't open $clonefile file";
my @Clones = <CLONES>;
close CLONES;

my @Clones2 =();

foreach my $clone(@Clones){
  if ($clone =~ /\d+/){
    $clone =~ s/\s//g;
    push ( @Clones2, $clone);
  }
}

return @Clones2;
}



