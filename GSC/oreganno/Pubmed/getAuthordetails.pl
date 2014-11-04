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
#my $outfile="/home/obig/Projects/oreganno/scripts/Pubmed/fetch_results.txt";

#my $pmid_list_file="/home/obig/Projects/oreganno/scripts/Pubmed/pmid_test_set.txt";
#my $outfile="/home/obig/Projects/oreganno/scripts/Pubmed/fetch_results_test.txt";

#my $pmid_list_file="/home/obig/Projects/oreganno/scripts/Pubmed/fetch_results_problems_pmids.txt";
#my $outfile="/home/obig/Projects/oreganno/scripts/Pubmed/fetch_results_problems_new_results.txt";

my $outfile="/home/obig/Projects/oreganno/scripts/Pubmed/fetch_results_author_details.txt";

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
  my $efetch_result_xml_ref = XMLin($efetch_result,ForceArray => 1);
  #my $efetch_result_xml_ref = XMLin($efetch_result);

  my @pubmed_records = @{$efetch_result_xml_ref->{PubmedArticle}};
  #print Dumper($efetch_result_xml_ref);
  #print Dumper(@pubmed_records);
  foreach my $pubmed_record_ref(@pubmed_records){
    #print Dumper($pubmed_record_ref);
    my $pubmed_id=$pubmed_record_ref->{'MedlineCitation'}[0]->{'PMID'}[0];
    print "$pubmed_id\n";
    #Get author details
    #Occasionally, no author details are defined. Leave empty or skip these
    unless($pubmed_record_ref->{'MedlineCitation'}[0]->{'Article'}[0]->{'AuthorList'}[0]->{'Author'}){
      print OUTFILE "$pubmed_id\t","\n";
      next;
    }
    my @authorlist=@{$pubmed_record_ref->{'MedlineCitation'}[0]->{'Article'}[0]->{'AuthorList'}[0]->{'Author'}};
    #print Dumper(@authorlist);
    my @all_authors;
    foreach my $author (@authorlist){
      my $forename=$author->{'ForeName'}[0];
      my $lastname=$author->{'LastName'}[0];
      my $initials=$author->{'Initials'}[0];
      my $author_details="$forename,$initials,$lastname";
      push (@all_authors, $author_details);
    }
    #Print out results to file
    print OUTFILE "$pubmed_id\t",join(";", @all_authors),"\n";
    #print "$pubmed_id\t",join(";", @all_authors),"\n";

  }
}
close OUTFILE;

