#!/usr/local/bin/perl -w

#This script should run the EMBOSS program infoseq on some sequence and output
#the results to a file

my $emboss = "/home/pubseq/BioSw/EMBOSS/020821/EMBOSS-2.5.0/emboss";
my $testfile = "/mnt/disk1/home/obig/emboss/testseq";

open ( TESTSEQ, $testfile) or die "Cannot open file $testfile\n";
my @testseq = <TESTSEQ>;
close TESTSEQ;

shift @testseq;
my $sequence = join( '', @testseq);
$sequence =~ s/\s//g;

print "\nTest sequence: ",$sequence,"\n";

#Use EMBOSS to determine percent GC
my $pgc = `$emboss/infoseq $testfile -only -pgc`;
chomp $pgc;

#Use EMBOSS to determine length
my $length = `$emboss/infoseq $testfile -only -length`;
chomp $length;

print "\nEMBOSS percent GC:",$pgc,"\n";
print "\nEMBOSS length:",$length,"\n";

my ($pgc2,$length2) = GCpercent($sequence);
print "\nPerl percent GC ",$pgc2,"\n";
print "\nPerl length ",$length2,"\n";
exit;



################################################
#Subroutine to Determine GC Percent
###############################################

sub GCpercent {

my($DNA) = @_;
my $dnalength = length($DNA);

my $gccontent=0;

while($DNA =~ /[cg]/ig){$gccontent++}

my $gcpercent = 100*($gccontent/$dnalength);
return ($gcpercent,$dnalength);

}
