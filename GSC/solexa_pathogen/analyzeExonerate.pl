#!/usr/bin/perl

use strict;

#C4 Alignment:
#------------
#         Query: LSAGE_Breast_fibroadenoma_MD:mammary:699818
#        Target: gi|56787868|gb|AY689437.1| Deerpox virus W-1170-84, complete genome:[revcomp]
#         Model: ungapped:dna2dna
#     Raw score: 105
#   Query range: 0 -> 21
#  Target range: 156491 -> 156470

#      1 : CATGCATTTATTTTTTATATT :     21
#          |||||||||||||||||||||
# 156491 : CATGCATTTATTTTTTATATT : 156471

my($q,$t);
my $top;
my $e;
my $sum=0;

###########################


#print "QUERY CENTRIC\n";

open(IN, $ARGV[0]);
while(<IN>){
   chomp;
   if(/Query\:\s+(.*)/){
      $q=$1;
   }elsif(/Target\:\s+(.*)/){
      $t=$1;
      #$top->{$q}++; 
      if($t=~/zebrafish|mouse|mice|murine|musculus|scrofa/i){
      }elsif(! exists $e->{$q}{$t}){
         $top->{$q}++;
         $e->{$q}{$t}++;
         $t="";
         $q="";
      }
   }
}
my $ct=0;
foreach my $qry (sort {$top->{$b}<=>$top->{$a}} keys %$top){
   $ct++;
   print "$ct.\n";
   my $list=$e->{$qry};
   print "Number of times query hit distinct sequences:$top->{$qry}:$qry\n";$sum+=$top->{$qry}++;
   print ">$qry\n";
   foreach my $i (keys %$list){
      print "\t$i\n";
   }
}



close IN;

my $seen_it;
my $e;
my $t;
my $q;
my $top;

my $tot=0;
print "HIT-CENTRIC\n";
open(IN, $ARGV[0]);
while(<IN>){
   chomp;
   if(/Query\:\s+(.*)/){
      $q=$1;
   }elsif(/Target\:\s+\S+\s+([^\:]*)/){
      $t=$1;
      $top->{$t}++ if (! exists $e->{$t}{$q});
      $e->{$t}{$q}++;
      $t="";
      $q="";
   }
}

TOP:
foreach my $hit (sort {$top->{$b}<=>$top->{$a}} keys %$top){
   my $flag=0;
   if($hit=~/zebrafish|mouse|murine|musculus|scrofa/i){
      #
   }else{
      my $list=$e->{$hit};
      $sum+=$top->{$hit}++;
      my $t;
      foreach my $i (keys %$list){
         my @a=split(/\:/,$i);
         if(! defined $seen_it->{$i}){
            $seen_it->{$i}++;
            my $concat = $a[0] . ":" . $a[1];
            $t->{$concat}++;
         }
      }
      my $cttag=0;
      my ($li,$cl)=(0,0);
      foreach my $ty (sort {$t->{$b}<=>$t->{$a}} keys %$t){
         $li++;
         my @a=split(/\:/,$ty);
         #print "HIT: $hit\n" if (! $flag);
         #print "\t$t->{$ty}\t$ty \n";
         $cttag+=$t->{$ty};
         $flag++;
      }
      #print "\t(TOTAL UNIQUE TAGS: $cttag)" if($flag);
      #print " ALL CANCER" if ($li==$cl && $flag && $li);
      #print "\n\n" if ($flag);
      my $ss = substr($hit,0,60);
      print "$ss,$cttag\n" if ($cttag);
      $tot+=$cttag;
   }
}

 

#print "Total tags: $tot\n";
