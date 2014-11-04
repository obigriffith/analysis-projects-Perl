#!/usr/local/bin/perl -w

use strict;

my $dir = "/home/obig/perl/UNIGENE/Assemblies";
chdir($dir);

my @dirlist = `ls`;
foreach my $subdir(@dirlist){
chomp $subdir;
print "subdir:$subdir\n";

  my $edit_dir = "$dir/"."$subdir/"."edit_dir/";

print "edit_dir:$edit_dir\n";

  chdir($edit_dir);
    `phredPhrap`;
}
exit;
