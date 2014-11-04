#!/usr/bin/perl -w
#!/usr/local/bin/perl -w

#take GEO SOFT file and produce a single file for clustering analysis
use strict;
use Getopt::Std;

getopts("f:o:n:rlsc");
use vars qw($opt_f $opt_o $opt_l $opt_n $opt_r $opt_s $opt_c);

unless ($opt_f){
  &printDocs;
}
my $save_input_seperator = $/; 
my (%Data, %Data_inv, %Exp, %taglist);
my ($outfile, $gene_count, $sample, $exp_count, $series);
my $geofile = $opt_f;
my $heading_count = 0;
my $sample_cutoff = 1;

if ($opt_o){$outfile=$opt_o;}
if ($opt_n){$sample_cutoff=$opt_n;}

print "\nThis script will attempt to process a GEO soft file into \na single datafile for clustering analysis, with experiments across the columns and genes along the rows\n\n";

if ($opt_o){open (OUTFILE, ">$outfile") or die "can't open $outfile for write\n";}

#set input separator so that GSM records are easy to get.
$/ = "^";

open (GEOFILE, $geofile) or die "can't open $geofile\n";
my $first_entry = <GEOFILE>; #Because of nature of input separator, first $entry will be empty, this skips it.
while (<GEOFILE>){
  my $entry = $_;
  $sample = "no_sample"; #assume no sample id until found
  $series = "no_series"; #assume no series id until found
  my $seriescount = 0; #most samples belong to only one series but some belong to multiple.  Have to keep track
  my $total_tag_count = 0;
  $gene_count=0;
  my @lines = split ("\n" , $entry);
  foreach my $line (@lines){
    #check for start of new sample record
    if ($line=~/^sample\s?=\s?(\S+)/i){
      $sample=$1;
      #$Exp{$sample}='0';
      print "processing $sample\n";
    }
    #Check for series ID
    if ($line=~/^\!Sample_series_id\s+\=\s+(GSE\d+)/i){ #make sure this captures all series ids
      $series=$1;
      $seriescount++;
      print "$sample belongs to series $series\n";
      if ($seriescount>1){ #if more than one series id is found for the sample, $seriescount > 1, and $series is set to "mult_series"
	$series="mult_series";
      }
    }
    #Look for column headings for detection call or p-value
    if ($line=~/^TAG\s+COUNT/){
      $Exp{$series}{$sample}='0'; #once headings are found, sample and series should be known,
      $heading_count++;
      print "column headings found: $line\n";
    }

    #Get Tag and Count
    if ($line=~/^([ACGTacgt]{10})\s+(\d+)/){
      my $tag = $1;
      my $count = $2;
      $Data{$tag}{$sample}=$count;
      $gene_count++;
      $total_tag_count = $total_tag_count + $count;
    }
  }
  print "$gene_count tags processed with $total_tag_count total tag count\n";
  if ($gene_count == 0){print "No tags found\n";}
  $Exp{$series}{$sample}=$total_tag_count;
  print "finished processing $sample\n\n"
}
close GEOFILE;

my $final_gene_count = keys %Data;

#filter out tags not present in n or more samples
foreach my $tag (sort keys %Data){
  my $datacount = keys %{$Data{$tag}};
  if ($datacount >= $sample_cutoff){
    $taglist{$tag}++; #create a list of tags which have sufficient samples
  }
}

#Create output file with all data.
if ($opt_o){
  #First print experiments across top of file
  print OUTFILE "Gene";
  foreach my $series (sort keys %Exp){
    foreach my $experiment (sort keys %{$Exp{$series}}){
      if ($opt_s){ #If specified, include series name in header
	print OUTFILE "\t$series"."_"."$experiment";
      }else{
	print OUTFILE "\t$experiment";
      }
      $exp_count++;
    }
  }

  print OUTFILE "\n";

  print "$exp_count samples and $final_gene_count genes processed:\n";

  #Then fill in data for each tag
  foreach my $tag (sort keys %Data){
    unless($taglist{$tag}){next;} #skip tag unless it made it past sample number filter.
    print OUTFILE "$tag";
    my $datacount = keys %{$Data{$tag}};
    #print "processing $datacount datapoints for $tag\n";
    foreach my $series (sort keys %Exp){
      foreach my $exp (sort keys %{$Exp{$series}}){
	my $data;
	if ($Data{$tag}{$exp}){
	  $data = $Data{$tag}{$exp};
	  if ($opt_r){
	    my $freq_data;
	    if ($opt_c){ #add 1 to count before calculating frequency if requested
	      $freq_data = ((($data + 1)*10000)/($Exp{$series}{$exp}));
	    }else{
	      $freq_data = ((($data)*10000)/($Exp{$series}{$exp}));
	    }
	    $data = $freq_data;
	  }
	  if ($opt_l){
	    my $log_data = log($data);
	    $data = $log_data;
	  }
	  my $formatted_data = sprintf ("%.4f",$data);
	  print OUTFILE "\t$formatted_data";
	}else{
	  print OUTFILE "\t";
	}
      }
    }
    print OUTFILE "\n";
  }
  close OUTFILE;
}

sub printDocs{
print "Must supply a file containing the list of files to assemble into one data set\n";
print "Options:\n";
print "-f infile.txt\n";
print "-o outfile.txt\n";
print "-n 10 specifies that tag must be present in 10 or more samples to be included in output (default=1)\n";
print "-r option to specify frequencies instead of raw data (((tagcount) x 10000)/total tag count)\n";
print "-l option to specify natural log\n";
print "-s option to include series in experiment name across header\n";
print "-c option to add 1 to each count before calculating frequency (((tagcount + 1) x 10000)/total tag count)\n";
exit;
}
