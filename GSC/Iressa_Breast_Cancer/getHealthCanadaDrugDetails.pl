#!/usr/bin/perl -w

use strict;
use LWP::Simple;
use Data::Dumper;
use HTML::TokeParser;

my $druglistfile="/home/obig/Projects/Iressa_Breast_Cancer/drugs/exonerate/Gene_level/iressa_ht3_AC_BF_2fold_up_DrugDetails.txt";
#my $druglistfile="/home/obig/Projects/Iressa_Breast_Cancer/drugs/exonerate/Transcript_level/iressa_ht1_AC_BF_2fold_up_DrugDetails.txt";
#my $druglistfile="/home/obig/Projects/Iressa_Breast_Cancer/drugs/exonerate/Specific_Transcript_level/iressa_ht2_AC_BF_2fold_up_DrugDetails.txt";
#my $druglistfile="/home/obig/Projects/Iressa_Breast_Cancer/drugs/blast/GeneResults_A431_SUM149_overlap.drugDetails.txt";

#my $healthcan = "http://cpe0013211b4c6d-cm0014e88ee7a4.cpe.net.cable.rogers.com/dpdonline";
#my $healthcan = "http://205.193.93.51/dpdonline";
my $healthcan = "http://webprod.hc-sc.gc.ca/dpd-bdpp";

#my $outfile = "/home/obig/Projects/Iressa_Breast_Cancer/drugs/exonerate/Gene_level/iressa_ht3_AC_BF_2fold_up_HealthCanDrugdetails.txt";
#my $outfile = "/home/obig/Projects/Iressa_Breast_Cancer/drugs/exonerate/Transcript_level/iressa_ht1_AC_BF_2fold_up_HealthCanDrugdetails.txt";
#my $outfile = "/home/obig/Projects/Iressa_Breast_Cancer/drugs/exonerate/Specific_Transcript_level/iressa_ht2_AC_BF_2fold_up_HealthCanDrugdetails.txt";
#my $outfile = "/home/obig/Projects/Iressa_Breast_Cancer/drugs/blast/GeneResults_A431_SUM149_overlap.HealthCanDrugDetails.txt";
my $outfile = "test.txt";

open (OUTFILE, ">$outfile") or die "can't open $outfile for write\n";

#Get drug list
open (DRUGS, $druglistfile) or die "can't open $druglistfile\n";
my %drugs;
my @drugs_generics;
my $header = <DRUGS>;
while (<DRUGS>){
  chomp;
  my @data = split ("\t", $_);
  $drugs{$data[2]}{'gene_id'}=$data[0];
  $drugs{$data[2]}{'uniprot_id'}=$data[1];
  $drugs{$data[2]}{'generic_name'}=$data[3];
  $drugs{$data[2]}{'brand_names'}=$data[6];
}
close DRUGS;

#my $generic="porfimer";
#my $generic="askdjfaoisrwer";
#my $generic="tositumomab";
#my $din="02020033";

#For each drug, obtain details from Health Canada (if available)
print OUTFILE "gene_id\tuniprot_id\tdrug\tgeneric_name\tproduct_name\tDIN\tcompany\tclass\tdosage_form\troute_admin\tpackaging\tactive_ing_strength\n";
foreach my $drug (sort keys %drugs){
  my $generic=$drugs{$drug}{'generic_name'};
  my $gene_id=$drugs{$drug}{'gene_id'};
  my $uniprot_id=$drugs{$drug}{'uniprot_id'};
  print "Searching HealthCan for $drug ($generic)\n";
  #my $searchRequest_genericname = "$healthcan/searchRequest.do?activeIngredient=$generic&status=1";
  my $searchRequest_genericname = "$healthcan/dispatch-repartition.do?activeIngredient=$generic&status=1";


  #print "$searchRequest_genericname\n";
  my $search_result=getSearchResult($searchRequest_genericname);

  print "$search_result\n";

  #Determine whether search result is 0, 1 or more hits.
  #For no result
  if ($search_result=~/No\sMatch\sFound/){
    print "No match found for $generic\n";
    print OUTFILE "$gene_id\t$uniprot_id\t$drug\t$generic\tNo Match\n";
    #Try Brand Names instead???
    #my $brandName="Photofrin";
    #my $searchRequest_brandname = "$healthcan/searchRequest.do?brandName=$brandName&status=1";
  }elsif($search_result=~/Active\sIngredient\sinvalid/){
    print "Active Ingredient invalid for $generic\n";
    print OUTFILE "$gene_id\t$uniprot_id\t$drug\t$generic\tActive Ingredient invalid\n";
    #Try Brand Names instead???
  }

  #For single result
  if ($search_result=~/Product Name:\s(.+)\sDIN:\s(\d+).+Company:/){
    print "Single match found\n";
    my ($product_name,$DIN,$company,$class,$dosage_form,$route_admin,$packaging,$active_ing_strength)=&parseDINpage($search_result);
    print "\n\n$gene_id\t$uniprot_id\t$drug\n$product_name\n$DIN\n$company\n$class\n$dosage_form\n$route_admin\n$packaging\n$active_ing_strength\n\n";
    print OUTFILE "$gene_id\t$uniprot_id\t$drug\t$generic\t$product_name\t$DIN\t$company\t$class\t$dosage_form\t$route_admin\t$packaging\t$active_ing_strength\n";
  }

  #For multiple results
  if ($search_result=~/\d+\sResults\sFound\,\s\d+\-\d+\sare\sDisplayed/){
    print "Multiple matches found, retrieving individual records\n";
    my @dins;
    while ($search_result=~/A\s(\d{8})\s/g){
      push (@dins, $1);
      print "DIN: $1 found\n";
    }
    foreach my $din (@dins){
      my $searchRequest_din = "$healthcan/searchRequest.do?din=$din&status=1";
      my $search_result = getSearchResult($searchRequest_din);
      #print "$search_result\n";
      my ($product_name,$DIN,$company,$class,$dosage_form,$route_admin,$packaging,$active_ing_strength)=&parseDINpage($search_result);
      print "\n\n$gene_id\t$uniprot_id\t$drug\n$product_name\n$DIN\n$company\n$class\n$dosage_form\n$route_admin\n$packaging\n$active_ing_strength\n\n";
      print OUTFILE "$gene_id\t$uniprot_id\t$drug\t$generic\t$product_name\t$DIN\t$company\t$class\t$dosage_form\t$route_admin\t$packaging\t$active_ing_strength\n";
    }
  }
}
close OUTFILE;

sub parseDINpage{
  my $search_result = shift;
  my $product_name="NA";
  my $DIN="NA";
  my $company="NA";
  my $class="NA";
  my $dosage_form="NA";
  my $route_admin="NA";
  my $packaging="NA";
  my $active_ing_strength="NA";
  if ($search_result=~/Product Name:\s(.+)\sDIN/){$product_name=$1;}
  if ($search_result=~/DIN:\s(\d+)/){$DIN=$1;}
  if ($search_result=~/Company:\s(.+)\sClass/){$company=$1;}
  if ($search_result=~/Class:\s(.+)\sDosage/){$class=$1;}
  if ($search_result=~/Dosage\sForm\(s\):\s(.+)\sRoute\sof\sAdministration/){$dosage_form=$1;}
  if ($search_result=~/Route\sof\sAdministration\(s\):\s(.+)\sNumber\sof\sActive\sIngredient/){$route_admin=$1;}
  if ($search_result=~/Packaging:\s(.+)\sActive\sIngredient\sGroup\sNumber/){$packaging=$1;}
  if ($search_result=~/Active\sIngredient\(s\)\sStrength\s(.+\S+)\s+Last/){$active_ing_strength=$1;}
  return ($product_name,$DIN,$company,$class,$dosage_form,$route_admin,$packaging,$active_ing_strength);
}

sub getSearchResult{
  my $searchRequest=shift;
  print "Attempting to get $searchRequest\n";
  my $searchRequest_result = get($searchRequest);
  my $p = HTML::TokeParser->new(\$searchRequest_result);
  my $search_result;
  while (my $token = $p->get_tag("p","td")) {
    my $text = $p->get_trimmed_text("p","/td");
    $search_result.="$text ";
  }
  sleep(3);
  return ($search_result);
}
