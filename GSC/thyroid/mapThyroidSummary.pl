#!/usr/local/bin/perl -w

use strict;
use Data::Dumper;
use Getopt::Std;

#This script takes a Data summary file and multiple mapping files for Affy probes, Sage tags, clone accessions
#Then, maps all these different features to a common id (Entrez)
getopts("o:");
use vars qw($opt_o);
my $outfile=$opt_o;
my $data_summary_file = "/home/obig/Projects/thyroid/processed_data/Thyroid_literature_data_summary6.txt";
my $sagemapfile = "/home/obig/Projects/thyroid/mapping_files/SAGE/Thyroid_literature_data_summary3_Tag_uniqlist_2_MGCRefseq_2_EntrezID.txt";
my $cDNAmapfile = "/home/obig/Projects/thyroid/mapping_files/Accession/gene2accession_29jul05_taxon9606";
my $Affy_U95A_v2mapfile = "/home/obig/Projects/thyroid/mapping_files/Affymetrix/HG_U95Av2_annot.2.tsv";
my $Affy_U133Amapfile = "/home/obig/Projects/thyroid/mapping_files/Affymetrix/HG-U133A_annot.2.tsv";
my $Entrez_info_file = "/home/obig/Projects/thyroid/mapping_files/Other/gene_info_02Aug05_taxon9606";
my $Entrez_history_file ="/home/obig/Projects/thyroid/mapping_files/Other/gene_history_05Aug05_taxon9606";
my $cDNA_David_mapfile = "/home/obig/Projects/thyroid/mapping_files/Accession/DAVID_2_1_GenbankAccesion_2_Entrez_04Aug05_taxon9606.txt";

my %SAGEMAP; my %CDNAMAP; my %AFFYMAP; my %ENTREZINFO; my %ENTREZMAP; my %ENTREZSYN; my %ENTREZSYNMAP; my %ENTREZHIST;
my %DATA;
my %GENES; my %GENELIST; my %GENESTATS;
my $entry_count=0;

&getSAGEmap();
#Note, currently only set up to do getcDNAmap or getcDNAmap2 not both
#&getcDNAmap(); #map accessions by NCBI files
&getcDNAmap2(); #map accessions by DAVID resource mapfile
&getAffymap();
&getEntrezinfo();
&getEntrezHistory();

#Process data summary file into a hash
open (SUMMARYDATA, $data_summary_file) or die "can't open $data_summary_file\n";
#Retrieve column headings from first line
my $firstline = <SUMMARYDATA>;
chomp $firstline;
my @headers = split ("\t",$firstline);
my $num_cols=@headers;
#print Dumper (@headers);
#print "\n$num_cols columns found\n";

#Go through each line of data and store in a hash
while (<SUMMARYDATA>){
  if ($_=~/^\d+/){$entry_count++;} #If lines starts with a study number, assume it represents a valid entry
  my @data = split ("\t",$_,-1);
  my $num_entries=@data;
  my $i=0;
  my $study_number = $data[0];
  for ($i=0; $i<$num_cols; $i++){
    my $data_entry=$data[$i];
    $data_entry =~ s/\"//g; #Remove any quotes
    $data_entry =~ s/\s+$//; #Remove any trailing whitespace
    #print "$headers[$i]: \"$data_entry\"\n";
    $DATA{$study_number}{$entry_count}{$headers[$i]}=$data_entry;
  }
  unless ($num_entries==$num_cols){print "error: unexpected data format\n";print Dumper(@data); exit;}
  #print "\n----end of record\n";
}
close SUMMARYDATA;
#print Dumper (%DATA);

#Now, go through hash and map different id types to common Entrez identifier.
foreach my $study (sort{$a<=>$b} keys %DATA){
  foreach my $entry (sort{$a<=>$b} keys %{$DATA{$study}}){

    #Set entrez id and name to NA unless found otherwise below.
    my $entrez_id='NA';
    my $entrez_name='NA';
    my $entrez_description='NA';
    my $map_method='NA';

    #for studies with accession as main identifier
    if ($DATA{$study}{$entry}{'Accession'}){
      my $accession = $DATA{$study}{$entry}{'Accession'};
      if ($CDNAMAP{$accession}{'rna'}){ #Check to see if the RNA accession exists in mapping file
	$entrez_id=$CDNAMAP{$accession}{'rna'};
	$map_method='clone_accession_2_NCBI_rna_accession_2_Entrez';
	#print "$study\t$entry\t$accession\t$entrez_id\t$entrez_name\n";
      }elsif($CDNAMAP{$accession}{'genomic'}){#Check to see if the genomic accession exists in mapping file
	$entrez_id=$CDNAMAP{$accession}{'genomic'};
	$map_method='clone_accession_2_NCBI_genomic_accession_2_Entrez';
      }elsif($CDNAMAP{$accession}{'protein'}){#Check to see if the protein accession exists in mapping file
	$entrez_id=$CDNAMAP{$accession}{'protein'};
	$map_method='clone_accession_2_NCBI_protein_accession_2_Entrez';
      }
    }
    #for studies with probe as main identifier
    elsif($DATA{$study}{$entry}{'Probe'}){
      my $probe = $DATA{$study}{$entry}{'Probe'};
      #Check to see if the probe exists in the mapping file
      if ($AFFYMAP{$probe}){
	$entrez_id=$AFFYMAP{$probe};
	$map_method='affy_probe_2_Entrez';
	#print "$study\t$entry\t$probe\t$entrez_id\t$entrez_name\n";
      }
    }
    #for studies with tag as main identifier
    elsif($DATA{$study}{$entry}{'Tag'}){
      my $tag = $DATA{$study}{$entry}{'Tag'};
      #Check to see if the probe exists in the mapping file
      if ($SAGEMAP{$tag}){
	$entrez_id=$SAGEMAP{$tag};
	$map_method='tag_2_refseq_or_mgc_2_Entrez';
	#print "$study\t$entry\t$tag\t$entrez_id\t$entrez_name\n";
      }
    }
    #For studies without accession,probe, or tag but with gene symbol.  Check to see if it is an Entrez gene symbol
    elsif($DATA{$study}{$entry}{'Gene'}){
      my $gene = $DATA{$study}{$entry}{'Gene'};
      #Check to see if the gene exists in the Entrez map file
      if ($ENTREZMAP{$gene}){
	$entrez_id=$ENTREZMAP{$gene};
	$map_method='Gene_symbol_2_NCBI_Entrez';
	#print "$study\t$entry\t$gene\t$entrez_id\t$entrez_name\n";
      }elsif($ENTREZSYNMAP{$gene}){ #If no standard mapping, check synonyms
	$entrez_id=$ENTREZSYNMAP{$gene};
	$map_method='Gene_symbol_2_NCBI_Synonym_2_Entrez';
	#print "$gene\t$entrez_id\t$entrez_name\n";
      }
    }

    #Check to see if Entrez ID was discontinued and replaced
    if ($ENTREZHIST{$entrez_id}){
      my $old_entrez = $entrez_id;
      print "$entrez_id discontinued\n";
      if ($ENTREZHIST{$entrez_id}=~/(\d+)/){#If discontinued Id was replaced by another number use the new id
	$entrez_id=$1;
      }else{ #Otherwise, set ID back to NA
	$entrez_id='NA';
      }
      print "$old_entrez replaced with $entrez_id\n";
    }

    #If an Entrez ID was found, look up the Entrez Name
    unless ($entrez_id eq 'NA'){
      $entrez_name=$ENTREZINFO{$entrez_id}{'name'};
      $entrez_description=$ENTREZINFO{$entrez_id}{'description'};
    }

    #Enter the entry#, entrez id and name into %DATA hash.  These values should be 'NA' unless found by one of the mapping methods above
    $DATA{$study}{$entry}{'Entrez_id'}=$entrez_id;
    $DATA{$study}{$entry}{'Entrez_name'}=$entrez_name;
    $DATA{$study}{$entry}{'Entrez_description'}=$entrez_description;
    $DATA{$study}{$entry}{'Entry'}=$entry;
    $DATA{$study}{$entry}{'Map_method'}=$map_method;
    $GENELIST{$entrez_id}=$entrez_name; #holds entrez id to name mapping for convenience later
  }
}

#Summarize genes according to number of studies, number of comparisons and study size
#Create a new hash %GENES to store comparisons and sample_counts
foreach my $study (sort{$a<=>$b} keys %DATA){
  foreach my $entry (sort{$a<=>$b} keys %{$DATA{$study}}){
    my $entrez_id = $DATA{$study}{$entry}{'Entrez_id'};
    if ($entrez_id eq 'NA'){next;}#skip genes without an Entrez ID
    my $entrez_name = $DATA{$study}{$entry}{'Entrez_name'};
    my $comparison = "$DATA{$study}{$entry}{'Cond1'}"."_vs_"."$DATA{$study}{$entry}{'Cond2'}";
    my $sample_count = $DATA{$study}{$entry}{'n_cond1'} + $DATA{$study}{$entry}{'n_cond2'}; #total sample size for comparison
    $GENES{$entrez_id}{$study}{$comparison}=$sample_count;
  }
}
#Now, create new hash %GENESTATS to store numbers of comparisons and studies
foreach my $gene (sort{$a<=>$b} keys %GENES){
  my $study_count = 0;
  my $comp_count = 0;
  my $total_sample_size = 0;
  foreach my $study (keys %{$GENES{$gene}}){
    $study_count++;
    foreach my $comp (keys %{$GENES{$gene}{$study}}){
      $comp_count++;
      $total_sample_size += $GENES{$gene}{$study}{$comp};
    }
  }
  $GENESTATS{$gene}{'n_studies'}=$study_count;
  $GENESTATS{$gene}{'n_comparisons'}=$comp_count;
  $GENESTATS{$gene}{'n_total_samples'}=$total_sample_size;
  print "$gene\t$GENELIST{$gene}\t$study_count\t$comp_count\t$total_sample_size\n";
}

#Finally, Add gene summary stats to %DATA hash
foreach my $study (sort{$a<=>$b} keys %DATA){
  foreach my $entry (sort{$a<=>$b} keys %{$DATA{$study}}){
    my ($n_studies, $n_comparisons, $n_total_samples);
    my $entrez_id = $DATA{$study}{$entry}{'Entrez_id'};
    if ($entrez_id eq 'NA'){#Set gene stats to NA by default in case no gene entry
      $n_studies = 'NA'; $n_comparisons = 'NA'; $n_total_samples = 'NA';
    }else{
      $n_studies=$GENESTATS{$entrez_id}{'n_studies'};
      $n_comparisons=$GENESTATS{$entrez_id}{'n_comparisons'};
      $n_total_samples=$GENESTATS{$entrez_id}{'n_total_samples'};
    }
    $DATA{$study}{$entry}{'n_studies'}=$n_studies;
    $DATA{$study}{$entry}{'n_comparisons'}=$n_comparisons;
    $DATA{$study}{$entry}{'n_total_samples'}=$n_total_samples;
  }
}

#Print out new summary file with Entrez mappings
#First, add new columns to headers array.
#push (@headers, 'Entrez_id'); push (@headers, 'Entrez_name');
splice(@headers, 1, 0, ('Entry', 'Entrez_id', 'Entrez_name', 'Entrez_description', 'n_studies','n_comparisons','n_total_samples','Map_method'));
my $new_num_cols=@headers;

if ($opt_o){
  open (OUTFILE, ">$outfile") or die "can't open $outfile\n";
  print OUTFILE join("\t",@headers),"\n";
  foreach my $study (sort{$a<=>$b} keys %DATA){
    foreach my $entry (sort{$a<=>$b} keys %{$DATA{$study}}){
      my $i;
      my @newdata;
      for ($i=0; $i<$new_num_cols; $i++){
	push (@newdata, $DATA{$study}{$entry}{$headers[$i]});
      }
      #print Dumper (@newdata)
      print OUTFILE join("\t",@newdata),"\n";
      print "$study\t$entry\t$DATA{$study}{$entry}{'Probe/Tag/Acc'}\t$DATA{$study}{$entry}{'Entrez_id'}\t$DATA{$study}{$entry}{'Entrez_name'}\n";
    }
  }
  close OUTFILE;
}

exit;

###Subroutines###
###Load Sage mapping data (tag to Entrez ID)
sub getSAGEmap{
print "Loading SAGE mapping data\n";
open (SAGEMAP, $sagemapfile) or die "can't open $sagemapfile\n";
while (<SAGEMAP>){
  if ($_=~/(\S+)\s+(\S+)/){
    $SAGEMAP{$1}=$2;
  }
}
close SAGEMAP;
#print Dumper(%SAGEMAP);
}

#Load cDNA clone mapping data (RNA nucleotide accession to Entrez ID)
sub getcDNAmap{
print "Loading cDNA accession mapping data\n";
open (CDNAMAP, $cDNAmapfile) or die "can't open $cDNAmapfile\n";
while (<CDNAMAP>){
  my @entry = split("\t", $_);
  my $entrez = $entry[1];
  my $rna_accession = $entry[3];
  my $prot_accession = $entry[5];
  my $gen_accession = $entry[7];
  if ($rna_accession =~/(\w+)(\.\d+)$/){$rna_accession=$1;}
  if ($prot_accession =~/(\w+)(\.\d+)$/){$prot_accession=$1;}
  if ($gen_accession =~/(\w+)(\.\d+)$/){$gen_accession=$1;}
  $CDNAMAP{$rna_accession}{'rna'}=$entrez;
  $CDNAMAP{$prot_accession}{'protein'}=$entrez;
  $CDNAMAP{$gen_accession}{'genomic'}=$entrez;
}
close CDNAMAP;
#print Dumper(%CDNAMAP);
}

#Load cDNA clone mapping data (RNA nucleotide accession to Entrez ID)
sub getcDNAmap2{
print "Loading cDNA accession mapping data from DAVID\n";
open (CDNADAVIDMAP, $cDNA_David_mapfile) or die "can't open $cDNA_David_mapfile\n";
while (<CDNADAVIDMAP>){
  my @entry = split("\t", $_);
  my $entrez = $entry[6];
  my $gen_accession = $entry[0];
  if ($entrez eq 'null'){next;} #don't map accession if Entrez listed as null
  $CDNAMAP{$gen_accession}{'rna'}=$entrez;
}
close CDNADAVIDMAP;
#print Dumper(%CDNAMAP);
}

#Load Affymetrix U95A and U133A mapping data (Affy probe_id to Entrez ID)
sub getAffymap{
  print "Loading Affymetrix U95A mapping data\n";
  open (U95AMAP, $Affy_U95A_v2mapfile) or die "can't open $Affy_U95A_v2mapfile\n";
  while (<U95AMAP>){
    my @entry = split("\t", $_);
    my $probe = $entry[0];
    my $entrez = $entry[18];
    if ($entrez =~ /\-\-\-/){next;} #skip entries with '---'
    if ($entrez =~ /\/\/\//){next;} #skip entries with '///'
    $AFFYMAP{$probe}=$entrez;
  }
  close U95AMAP;

  #Load Affymetrix U133A mapping data (Affy probe_id to Entrez ID)
  print "Loading Affymetrix U133A mapping data\n";
  open (U133AMAP, $Affy_U133Amapfile) or die "can't open $Affy_U133Amapfile\n";
  while (<U133AMAP>){
    my @entry = split("\t", $_);
    my $probe = $entry[0];
    my $entrez = $entry[18];
    if ($entrez =~ /\-\-\-/){next;} #skip entries with '---'
    if ($entrez =~ /\/\/\//){next;} #skip entries with '///'
    $AFFYMAP{$probe}=$entrez;
  }
  close U133AMAP;
  #print Dumper(%AFFYMAP);
}

#Load Entrez info file for gene symbols and synonyms
sub getEntrezinfo{
print "Loading Entrez info data\n";
open (ENTREZ, $Entrez_info_file) or die "can't open $Entrez_info_file\n";
while (<ENTREZ>){
  my @entry = split("\t", $_);
  my $entrez_id = $entry[1];
  my $entrez_name = $entry[2];
  my $entrez_description = $entry[8];
  my @synonyms = split('\|',$entry[4]);
  $ENTREZINFO{$entrez_id}{'name'}=$entrez_name;
  $ENTREZINFO{$entrez_id}{'synonyms'}=\@synonyms;
  $ENTREZINFO{$entrez_id}{'description'}=$entrez_description;
  $ENTREZMAP{$entrez_name}=$entrez_id;
  foreach my $synonym (@synonyms){
    $ENTREZSYN{$synonym}{$entrez_id}++;
  }
}
close ENTREZ;
#Go through %ENTREZSYN and find only unambiguous mappings
print "Creating synonym mappings\n";
foreach my $synonym (keys %ENTREZSYN){
  foreach my $entrez(keys %{$ENTREZSYN{$synonym}}){
    my $syn_map_count = keys %{$ENTREZSYN{$synonym}}; #make sure that synonym is only mapped to one entrez id
    if ($syn_map_count==1){
      $ENTREZSYNMAP{$synonym}=$entrez;
    }
  }
}
}

#Create hash of discontinued Entrez ids
sub getEntrezHistory{
print "Loading Entrez history data\n";
open (ENTREZHIST, $Entrez_history_file) or die "can't open $Entrez_history_file\n";
while (<ENTREZHIST>){
  my @entry = split("\t", $_);
  my $current_Entrez = $entry[1];
  my $discont_Entrez = $entry[2];
  $ENTREZHIST{$discont_Entrez}=$current_Entrez;
}
close ENTREZHIST;
}
