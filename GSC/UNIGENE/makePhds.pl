#!/usr/local/bin/perl -w

use strict;

my $dir = "/mnt/disk7/MGC/UNIGENE/Assemblies";
chdir($dir);
my $infile = "/mnt/disk1/home/obig/perl/UNIGENE/UnigeneSeq100.txt";
open (INFILE,$infile) or die "can't open $infile";
#my $description;
my $gb;
my $file;
my $linestatus = 0;
my $unigene;
my $phd_dir = "phd_dir";
my $chromat_dir = "chromat_dir";
my $edit_dir = "edit_dir";
my $poly_dir = "poly_dir";
my $fasta_dir = "fasta_dir";


#Go through file of first 100 Unigenes and make a folder of fasta files for each
#sequence for each Unigene
while (<INFILE>){
  my $line = $_;
  print "next line:$line\n";
  
  if ($line =~ /^>.+Hs\#\w+\s(.+?)\/.*gb=(\w+).*ug=Hs\.(\d+).*\n/){
#  if ($line =~ /^>\s\d+\s.+Hs\#\w+\s(.+?)\/.*gi=(\d+).*ug=Hs\.(\d+).*\n/){

#    print "found a match\n";
#    my $crap = <STDIN>;

    my $description = $1;
    $gb = $2;
    $unigene = $3;
    print "$description\n";
    $description =~ s/\s/_/g;
    $description =~ s/\W/_/g;
#    print "next line:$line\n";
    $file = "Hs_"."$unigene"."$description"."_gb"."$gb".".fasta";
    my $assemblydir = "$dir/"."Hs"."$unigene";
    makeDirectory($assemblydir);
    chdir($assemblydir);
    makeDirectory($phd_dir);
    makeDirectory($chromat_dir);
    makeDirectory($edit_dir);
    makeDirectory($poly_dir);
    makeDirectory($fasta_dir);
    chdir($fasta_dir);

    open (FILE,">$file") or die "can't open $file";
    print FILE $line;
    $linestatus =1;
    next;
  }

  if ($linestatus == 1){
    print FILE $line;
  }
}
close FILE;

#Convert all fasta files into Phd files
chdir($dir);
my @dirlist = `ls`;
foreach my $subdir(@dirlist){
chomp $subdir;
print "subdir:$subdir\n";

  my $fasta_dir = "$dir/"."$subdir/"."fasta_dir/";
  my $phd_dir = "$dir/"."$subdir/"."phd_dir/";

print "fasta_dir:$fasta_dir\n";
print "phd_dir:$phd_dir\n";

  chdir($fasta_dir);
  my @list = `ls`;
  foreach my $file(@list){
    if ($file =~ /^.+\.fasta/){
    `fasta2Phd.perl $file`;
  }
  }
  `mv *.phd.* $phd_dir`;
}
exit;


sub makeDirectory{
  my $dir = shift;

  print "\n**********makeDirectory()";
  if(-e $dir){
    print "$dir already exists.  Skipping this function...\n";
  }
  else{
    mkdir($dir,0755);
    print "Created $dir.\n";
  }
}
