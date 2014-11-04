#!/usr/local/bin/perl58 -w

use LWP::Simple;
use XML::Simple;
use Data::Dumper;
use strict;

my $utils = "http://www.ncbi.nlm.nih.gov/entrez/eutils";
my $db="Pubmed";
my $rettype="full";
my $retmode="xml";
my $pmids_per_query=100;

my $pmid_list_file="/home/obig/Projects/oreganno/scripts/Pubmed/F1000_final_top58k_pmids.txt";
my $outfile="/home/obig/Projects/oreganno/scripts/Pubmed/fetch_results.txt";
#my $pmid_list_file="/home/obig/Projects/oreganno/scripts/Pubmed/pmid_test_set.txt";
#my $outfile="/home/obig/Projects/oreganno/scripts/Pubmed/fetch_results_test.txt";
#my $pmid_list_file="/home/obig/Projects/oreganno/scripts/Pubmed/fetch_results_problems_pmids.txt";
#my $outfile="/home/obig/Projects/oreganno/scripts/Pubmed/fetch_results_problems_new_results.txt";


open (OUTFILE, ">$outfile") or die "can't open $outfile\n";

open (PMIDS, $pmid_list_file) or die "can't open $pmid_list_file\n";

#Grab all pmids from file
my @pmids; 
while (<PMIDS>){
  if ($_=~/(\d+)/){
    push (@pmids, $1);
  }
}
close(PMIDS);

#Query pmids n number at a time. More efficient this way.
while (@pmids){
  my $i = 1;
  my $id_count = @pmids;
  print "$id_count PMIDs remaining\n";
  if ($id_count<$pmids_per_query){$pmids_per_query=$id_count;}#Set query size to remaining pmids for end of file
  my @query_list;
  for ($i=1; $i<=$pmids_per_query; $i++){
    #pull the pmid off the total list and add to sublist
    my $query=shift(@pmids); 
    push (@query_list,$query);
  }
  #submit query to ncbi, allowing 3 seconds between queries as requested by ncbi
  #print "Sleeping for 3 seconds so that NCBI is not flooded\n";
  sleep(3);
  my $query_list_string=join(",",@query_list);
  my $efetch = "$utils/efetch.fcgi?db=$db&id=$query_list_string&retmode=$retmode&rettype=$rettype";
  #print "\n$efetch\n";
  my $efetch_result = get($efetch);
  #print "\n------------------------------------------------------------\n$efetch_result\n\n";

  #Read XML data into perl data object using XML::Simple
  #my $efetch_result_xml_ref = XMLin($efetch_result,ForceArray => 1);
  my $efetch_result_xml_ref = XMLin($efetch_result);

  my @pubmed_records = @{$efetch_result_xml_ref->{PubmedArticle}};
  #print Dumper($efetch_result_xml_ref);
  #print Dumper(@pubmed_records);

  foreach my $pubmed_record_ref(@pubmed_records){
    #print Dumper($pubmed_record_ref);
    #exit;
    my $article_title=$pubmed_record_ref->{'MedlineCitation'}->{'Article'}->{'ArticleTitle'};
    my $journal_title=$pubmed_record_ref->{'MedlineCitation'}->{'Article'}->{'Journal'}->{'Title'};
    my $abbr_journal_title=$pubmed_record_ref->{'MedlineCitation'}->{'MedlineJournalInfo'}->{'MedlineTA'};
    my $pubmed_id=$pubmed_record_ref->{'MedlineCitation'}->{'PMID'};
    my $abstract=$pubmed_record_ref->{'MedlineCitation'}->{'Article'}->{'Abstract'}->{'AbstractText'};
    my $pub_year=$pubmed_record_ref->{'MedlineCitation'}->{'Article'}->{'Journal'}->{'JournalIssue'}->{'PubDate'}->{'Year'};
    my $pub_month=$pubmed_record_ref->{'MedlineCitation'}->{'Article'}->{'Journal'}->{'JournalIssue'}->{'PubDate'}->{'Month'};
    my $pub_day=$pubmed_record_ref->{'MedlineCitation'}->{'Article'}->{'Journal'}->{'JournalIssue'}->{'PubDate'}->{'Day'};
    #If no PubDate, try ArticleDate, then, pubmed pubdate, otherwise set to 1
    unless($pub_day){$pub_day=$pubmed_record_ref->{'MedlineCitation'}->{'Article'}->{'ArticleDate'}->{'Day'};}
    unless($pub_day){$pub_day="01";} #Can set day to 01 if not known. This not displayed in ORegAnno anyways.
    unless($pub_month){$pub_month=$pubmed_record_ref->{'MedlineCitation'}->{'Article'}->{'ArticleDate'}->{'Month'};}
    unless($pub_month){
      my $medline_date=$pubmed_record_ref->{'MedlineCitation'}->{'Article'}->{'Journal'}->{'JournalIssue'}->{'PubDate'}->{'MedlineDate'};
      if ($medline_date){
	if ($medline_date=~/\d{4}\s(\w{3})/){$pub_month=$1;} #grab first month from medline pubdate
      }
    }
    #unless($pub_month){$pub_month=$pubmed_record_ref->{'PubmedData'}->{'History'}->{'PubMedPubDate'}->{'Month'};} #use pubmed pubmonth as final resort
    unless($pub_month){$pub_month="01";} #If month or year still missing, leave as ?? and investigate before upload to db
    unless($pub_year){
      my $medline_date=$pubmed_record_ref->{'MedlineCitation'}->{'Article'}->{'Journal'}->{'JournalIssue'}->{'PubDate'}->{'MedlineDate'};
      if ($medline_date){
	if ($medline_date=~/(\d{4})\s/){$pub_year=$1;}
      }
    }
    unless($pub_year){$pub_year="????";}
    #Replace pub_month with number
    my $fixed_pub_month=&ConvertMonth($pub_month);
    my $formatted_pub_day=&convertDayMonthNumber($pub_day);
    my $formatted_pub_month=&convertDayMonthNumber($fixed_pub_month);
    #Print out results to file
    #print OUTFILE "$pubmed_id\t$abbr_journal_title\t$article_title\t$pub_year-$formatted_pub_month-$formatted_pub_day\t$abstract\n";
    #print "$pubmed_id\t$abbr_journal_title\t$article_title\t$pub_year-$formatted_pub_month-$formatted_pub_day\n";

  }
}
close OUTFILE;

sub ConvertMonth{
my $pub_month=shift;
$pub_month=~s/Jan/01/;
$pub_month=~s/Feb/02/;
$pub_month=~s/Mar/03/;
$pub_month=~s/Apr/04/;
$pub_month=~s/May/05/;
$pub_month=~s/Jun/06/;
$pub_month=~s/Jul/07/;
$pub_month=~s/Aug/08/;
$pub_month=~s/Sep/09/;
$pub_month=~s/Oct/10/;
$pub_month=~s/Nov/11/;
$pub_month=~s/Dec/12/;
return($pub_month);
}

sub convertDayMonthNumber{
my $daymonth=shift;
if (length($daymonth)<2){$daymonth="0".$daymonth;}
return($daymonth);
}
