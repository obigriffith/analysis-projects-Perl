#!/usr/bin/perl -w

use strict;
use Getopt::Std;
use Data::Dumper;

getopts("o:d:i:s:a:b:");
use vars qw($opt_o $opt_d $opt_i $opt_s $opt_a $opt_b);
unless ($opt_d && $opt_i && $opt_s){&printDocs();}

my $exp_dir = $opt_d;
my $tissue_info=$opt_i;
my $subsets=$opt_s;
my $outfile=$opt_o;
my $subset_min = $opt_a;
my $non_subset_max = $opt_b;

my @exp_files;
my $exp_count=0;
my %data;
my %info;
my %subsets;
my %exp_list;


#First load expression data for all genes and experiments to be considered.
#If experiments are stored individually in separate files, supply a directory and get all files
if ($opt_d){
  opendir(DIR, $exp_dir) || die "can't opendir $exp_dir: $!";
  my @files = readdir(DIR);
  closedir DIR;
  foreach my $entry(@files){if ($entry=~/SM\w+/){push (@exp_files, $entry)}}
}

#Go through each file and add data to a hash
print "\nLoading experiment files...\n";
foreach my $exp_file (@exp_files){
  my $tag_count=0;
  my $path = "$exp_dir/"."$exp_file";
  my $exp;
  if ($exp_file=~/(SM\w+)\./){#parse experiment name from filename
    $exp = $1;
    $exp_list{$exp}++;
    $exp_count++;
  }else{print "ERROR: $exp_file of unexpected format\n";}

  open (EXP_FILE, $path) or die "ERROR: can't open $path\n";
  while (<EXP_FILE>){
    if ($_=~/([ACGT]{10,17})\s+(\d+)/){
      my $tag=$1; 
      my $count=$2;
      $tag_count++;
      $data{$tag}{$exp}=$count;
    }else{print "ERROR: data not in expected format\n$_\n";exit;}
  }
  close EXP_FILE;
  print "$exp_count: $exp\t$tag_count tags\n";
}

print "$exp_count experiment files loaded\n";

#Now, for some subset of libraries we want to look for expression that is 'specific' to that subset
#We first need to know the tissue, subtissue and developmental stage information for each library
if ($opt_i){
  open (TISSUE_INFO, $tissue_info) or die "ERROR: can't open $tissue_info\n";
  my $header = <TISSUE_INFO>;
  while (<TISSUE_INFO>){
    chomp;
    my @info = split ("\t",$_,-1);
    $info{$info[3]}{'tissue'}=$info[0];
    $info{$info[3]}{'subtissue'}=$info[1];
    $info{$info[3]}{'stage'}=$info[2];
  }
close TISSUE_INFO;
}


#Second we need to know what subsets of libraries we are interested in:
if ($opt_s){
  open (SUBSETS, $subsets) or die "ERROR: can't open $subsets\n";
  while (<SUBSETS>){
    chomp;
    if ($_=~/(\S+)\t(\S+)\t(\S+)\t(\S+)/){ #watch out for lines of unexpected format
      my @entries = split ("\t",$_,-1);
      $subsets{$entries[0]}{$entries[1]}{'category'}=$entries[2];
      $subsets{$entries[0]}{$entries[1]}{'name'}=$entries[3];
    }
  }
close SUBSETS;
}

open (OUTFILE, ">$outfile") or die "can't open $outfile\n";

#Now get list of libraries for each subset of tissues/subtissues/stages
foreach my $subset(sort{$a<=>$b} keys %subsets){
  print "\n----------------------------------------------------\n";
  print "Finding experiments for subset: $subset\n";
  print "subset\tcondition\tcategory\tname\n";
  my $cond_count=0;
  my @conditions;
  my %exp_subset_temp;
  my %exp_subset;
  foreach my $condition(sort keys %{$subsets{$subset}}){
    $cond_count++;
    my $category = $subsets{$subset}{$condition}{'category'}; #should be one of 'tissue', 'subtissue', or 'stage'
    my $name = $subsets{$subset}{$condition}{'name'}; #The actual tissue, subtissue or stage
    my $description="$subsets{$subset}{$condition}{'category'}".":"."$subsets{$subset}{$condition}{'name'}";
    push (@conditions,$description);
    print "$subset\t$condition\t$category\t$name\n";
    foreach my $exp(keys %info){
      if ($info{$exp}{$category} eq $name){
	$exp_subset_temp{$exp}++;
      }
    }
  }
  foreach my $exp (keys %exp_subset_temp){
    if ($exp_subset_temp{$exp}==$cond_count){ #only include an experiment in the final list if it met all of the conditions for that subset
      $exp_subset{$exp}++;
    }
  }
  print "\nLibraries found that match condition(s)\n";
  foreach my $exp (keys %exp_subset){
    print "$exp\t$info{$exp}{'tissue'}\t$info{$exp}{'subtissue'}\t$info{$exp}{'stage'}\n";
  }
  #Get tags that are specific to this subset
  my $specific_tags_ref=&checkTagSpecificity(\%exp_subset);
  my %specific_tags = %$specific_tags_ref;

 #print summary of specific tags for each subset to file
  #print Header
  my @subset_exps;
  foreach my $subset_exp(sort keys %exp_subset){push (@subset_exps,$subset_exp);}
  print OUTFILE "Tag\tTissue/Stage\t","TotalTags\t",join("\t",@subset_exps),"\n";

  #Now print data for each tag
  foreach my $specific_tag(keys %specific_tags){
    print OUTFILE "$specific_tag\t";
    print OUTFILE join(";",@conditions),"\t";
    my $specific_tag_count_total=0;
    my @subset_tag_counts;
    foreach my $subset_exp(@subset_exps){
      my $specific_tag_count;
      if ($data{$specific_tag}{$subset_exp}){
	$specific_tag_count=$data{$specific_tag}{$subset_exp};
      }else{
	$specific_tag_count=0;
      }
      $specific_tag_count_total=$specific_tag_count_total+$specific_tag_count; #get total of tag count in subset
      push (@subset_tag_counts,$specific_tag_count);
    }
    print OUTFILE "$specific_tag_count_total\t",join("\t",@subset_tag_counts),"\n";
  }
}
close OUTFILE;
exit;

sub checkTagSpecificity{
  my $exp_subset_ref = shift @_;
  my %exp_subset = %$exp_subset_ref;
  my %exp_non_subset;
  my %specific_tags;

  print "Searching for tags with a least $subset_min tags in one or more subset library and less than $non_subset_max in all other libraries\n";
  #Need to get experiments that are not in subset
  foreach my $exp(keys %exp_list){
    unless ($exp_subset{$exp}){
      $exp_non_subset{$exp}++;
    }
  }

  #Then go through each tag and see if it is above some threshold in the subset but not in the non-subset
  foreach my $tag(%data){
    my $subset_tag=0;
    my $not_specific=0;
    foreach my $subset_exp(keys %exp_subset){
      unless($data{$tag}{$subset_exp}){next;}#many tags will not have any data for many experiments
      if ($data{$tag}{$subset_exp}>=$subset_min){
	#print "Tag found in subset: $tag\t$subset_exp\t$data{$tag}{$subset_exp}\n";
	$subset_tag=1;
      }
    }
    if ($subset_tag==1){#For each tag thats found Check to see if this tag is absent in other experiments
      foreach my $non_subset_exp(keys %exp_non_subset){
	unless($data{$tag}{$non_subset_exp}){next;}#many tags will not have any data for many experiments
	if ($data{$tag}{$non_subset_exp}>=$non_subset_max){#Check to see if that tag is present in non-subset list
	  $not_specific=1;
	  last; #stopping checking experiments in the non-subset list for this tag
	}
      }
    }else{next;}
    if ($not_specific==0){
      print "Tissue-specific tag found: $tag\n";
      $specific_tags{$tag}++;
    }
  }
  return(\%specific_tags);
}
sub printDocs{
print "Options:
-d Directory of expression files (Tag   Count)
-i Tissue info file (tissue   subtissue   stage   library)
-s Subsets file to specify what tissues, subtissues, or stages to investigate for tissue-specific expression (sub_number  cond_number   category   category name)
-a minimum tag count observed in subset
-b maximum tag count observed outside of subset

Expression file example:
TCCCGCCGTGAAGTGGA       8939
CTGACTCAAAATTGTAA       4886
ATCTGTGTTGGCTTCCT       2871

Tissue info file example:
Tissue  Sub_Tissue      Developmental_Stage     Library
Whole Embryo            Blastocyst - Theiler Stage 5    SM058
Whole Embryo            1 Cell - Theiler Stage 1        SM077
Whole Embryo            Morula - Theiler Stage 3        SM061
Second Branchial Arch           Theiler Stage 17        SM105

Subsets file example:
1	1	tissue	Heart
2	1	subtissue	Atria	
3	1	stage	Theiler Stage 19
";
exit;
}
