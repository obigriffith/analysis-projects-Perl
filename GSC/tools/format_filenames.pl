#!/usr/local/bin/perl -w

use strict;
use Getopt::Std;

getopts("d:f:cs");
use vars qw($opt_f $opt_d $opt_c $opt_s);

unless (($opt_f || $opt_d) && ($opt_c || $opt_s)){
print "You must specify either a file or directory containing files to be renamed\n";
print "-f filename\n";
print "-d directoryname\n";
print "-s flag to replace spaces with underscore\n";
print "-c flag to replace weird characters with underscore eg. ),(,/,\,|\n";
exit;
}

my @files;

if ($opt_f){
  @files = $opt_f;
}

if ($opt_d){
  opendir (DIR, $opt_d) or die "can't open $opt_d\n";
  @files = readdir DIR;
  closedir DIR;
}

foreach my $file (@files){
  my $newfile = $file;
  if ($opt_s){
    $newfile=~s/\s+/_/g;
  }
  if ($opt_c){
    $newfile=~s/[\|\\\(\)\[\]\?\=]/_/g;
  }
  unless ($newfile eq $file){
    print "renaming $file to $newfile\n";
    rename($file, $newfile) or die "can't rename $file\n";
  }
}

exit;
