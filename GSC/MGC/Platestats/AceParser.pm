#!/usr/local/bin/perl
# simple script to parse an Ace file to a text summary
# shows number of contigs, length and reads for each
# Y. Butterfield/R. Warren
# June 11, 2001.
# modified August 21st,2002
package main;

use strict;
use Data::Dumper;
use lib "/home/ybutterf/perl/lib/Statistics";
use ChiSquare2;
use Binomial;
use Runs;
require "/home/ybutterf/perl/lib/Phrap/Contig.pm";

#------------------------------------------------------------------------
sub SearchAceFileForMGC{

    my $clones = shift;
    my %clones=%$clones;
    # Opens the ace file and extracts information on the specified clone
    my $plate_id = shift;
    my $quadrant = shift;
    my $build = shift;
    my $contig = shift;
    my $mgc=shift;
    #print "MGC: $mgc\n";
    my $sequence_length=shift;
    my $ace_file = "/home/sequence/Projects/Human_cDNA/Assemblies/$plate_id$quadrant/edit_dir/$plate_id$quadrant.fasta.screen.ace.$build";
    #print "$ace_file\t$contig\n";
    #exit;
    open( INPUT,"$ace_file"); 
    my (%all_reads,$contig_orientation);
    while(<INPUT>){
	my ($curr_read,$start_site,$read_orientation,$location,$read_length);
	if ($_=~/^CO Contig$contig\s\d+\s\d+\s\d+\s(\w)$/){ 
	    #print "$_\n";
	    #found contig
	    #print "found contig...\n";

	    #now get orientation
	    $contig_orientation = $1;

	    until($_=~/AF/){           
		#go to section on AF reads
		$_=<INPUT>;
	    }
	    while($_=~/AF/){  
		#print "$_";
		#loop through all reads and put into a hash
		if ($_=~/AF\s(TRANS__\w+\.?\d?)\s?(\w+)\s?(\-?\d+)/){
		    #print "$_";
		    $curr_read = $1;
		    $read_orientation = $2;
		    $location = $3;
		    $all_reads{$curr_read}{'location'}=$location;
		    $all_reads{$curr_read}{'orientation'}=$read_orientation;
		}
		$_=<INPUT>;
	    }
	    until($_=~/RD/){           
		#go to section on RD reads
		$_=<INPUT>;
	    }
	}	
	if($_=~/^RD/){
	    foreach my $curr_read (keys %all_reads){	
		#print "$curr_read\n";
		if ($_=~/RD\s?$curr_read\s?(\d?)/){
		    #print "$_\n";
		    $read_length=$1;
		    $location=$all_reads{$curr_read}{'location'};
		    #print "$location\n";
		    $read_orientation=$all_reads{$curr_read}{'orientation'};
		    $start_site = &AnalyseRead($curr_read,$read_orientation,$contig_orientation,$location,$read_length,$sequence_length); #if start_site = -1, then is inserted into vector as determined by above function 
		    if ($start_site > 0){
			$clones{$mgc}{'start_sites'}++;
			push(@{$clones{$mgc}{'start_site_index'}},$start_site);
		    }
		}
	    }
	}	
    }    
    close INPUT;        
}
    
#------------------------------------------------------------------------------
#By far the most useful piece of code here: collects per 1)contigs
# 2)sequence & 3)libraries

sub get_Contigs_from_Ace{

    # get ace file
    # Conclusion: for large ace files, this takes forever!  
    # i.e. rhodococcus whole genome shotgun assembly

    my $ace_file = shift;
    my $outputfile = shift;

    my $tmp;
    my ($counta, $countt, $countc, $countg);
    my $totalbases;
    my $consensus;
    my ($perca, $perct, $percc, $percg);
    my $l;

    my %library;
    my @tig;
    my $countig=0;
    my @count;

    unless ( open(OUTFILE, ">>$outputfile") ){
      print "Cannot open file \"$outputfile\" to write to !\n\n";
      exit;
    }



    #print "asdf> $ace_file\n";
    open(ACE,$ace_file);
    # get contig info
    my %contig;
    my $rdcount=0;
    my $current_contig_number;

    while (<ACE>){
	
	my $sequence;
	my $qualities;

	if (/^CO\s+\D+(\d+)\s+(\d+)\s+(\d+)/){          #change Contig for \D (non-digit)
            $countig++;                               #count contig
            push @tig, $1;                            #make array of contig number (disordered or not)
            push @count, $countig;   
            
	    $current_contig_number = $1;
	    $contig{$1}{'total_length'}=$2;
	    $contig{$1}{'reads'}=$3;
	    $_=<ACE>;
	    until ($_=~/BQ/){ 
		chomp $_;
                $sequence .= $_;  
                $tmp=$_;
                $l+=length($tmp);
                while ($tmp =~ /(a|c|g|t|x|n)/gi){

                    $consensus++ if ($1 eq 'A' or $1 eq 'T' or $1 eq 'G' or $1 eq 'C');

                    my $base=lc($1);

                    $counta++ if ($base eq 'a');
                    $countt++ if ($base eq 't');
                    $countg++ if ($base eq 'g');
                    $countc++ if ($base eq 'c');
                }
		$_=<ACE>;
	    }
	    $_=<ACE>;
	    until ($_=~/AF/){ 
		chomp $_;
		$qualities .= $_;  
		$_=<ACE>;
	    }
 
	    #remove all the pads globally from the sequence
	    $sequence=~s/\*//g;
	    $contig{$current_contig_number}{'sequence'}=$sequence;
	    @{$contig{$current_contig_number}{'contig_qualities'}}=split(" ",$qualities);
	    my ($err,$phred);
	    ($err,$phred) = GetErrRate(\@{$contig{$current_contig_number}{'contig_qualities'}});
	    $contig{$current_contig_number}{'error_rate'}=sprintf "%.2f", $err;
	    $contig{$current_contig_number}{'average_phred'}=$phred;
	}
        elsif (/^RD\s+(\w{5})(\w+)\.(\w+)(\.?\d?)_([a-zA-Z]\d{2})(_._)(\d+)\.(\w+).*/gis){   #from ABI
           $library{$1}{$current_contig_number}++;  #all contigs saved by libraryID
           #print "$1\t$current_contig_number\n";
                                                    #count amount of reads per given contig
        }
    }
    # Contig statistics:
    my $contignumber = 0;
    my $totalerror = 0;
    my $gooderror = 0;
    my $totalphred = 0;
    my $goodphred = 0;
    my $totalreads = 0;
    	foreach my $current_contig_number (sort {$contig{$a}<=>$contig{$b}} keys %contig){
	    my $seqtemp = $contig{$current_contig_number}{'sequence'};

	    # Percent GC determination
	    my $contigGC = ($seqtemp =~ tr/GgCc//);
	    my $percentGC = ($contigGC/length($seqtemp))*100;

	    # Keep track of number of Contigs
	    $contignumber = ++$contignumber;

	    #Keep track of total error rate and number of contigs with error rate<0.200
	    my $errortemp = $contig{$current_contig_number}{'error_rate'};
	    if ($errortemp <= 0.2){
	      $gooderror = ++$gooderror;
	    }
	    $totalerror = ($totalerror + $errortemp);

	    #Keep track of total average phred scores and number of contigs with avg. phred>70
	    my $phredtemp = $contig{$current_contig_number}{'average_phred'};
	    if ($phredtemp>=70){
	      $goodphred = ++$goodphred;
	    }
	    $totalphred = ($totalphred + $phredtemp);

	    #Keep track of total number of reads
	    my $readstemp = $contig{$current_contig_number}{'reads'};
	    $totalreads = ($totalreads + $readstemp);

	    #HERE ARE SOME PRINT STATEMENTS FOR TESTING ERROR
	    #print "Contig:$current_contig_number\n";
	    #print "sequence:".$contig{$current_contig_number}{'sequence'}."\n";
	    #print "length:".length($contig{$current_contig_number}{'sequence'})."\n";
	    #print "error:".$contig{$current_contig_number}{'error_rate'}."\n";
	    #print "average phred:".$contig{$current_contig_number}{'average_phred'}."\n";
	    #print OUTFILE "reads:".$contig{$current_contig_number}{'reads'}."\n";
	    #print OUTFILE "GC count:".$contigGC . "\n";
	    #print OUTFILE "Percent GC:".$percentGC . "\n";
	    #print OUTFILE "---------------------------\n";
	}

   close ACE;

   $totalbases=$counta+$countt+$countg+$countc;

   if ($totalbases ne '0'){
      $perca=$counta/$totalbases*100;
      $perct=$countt/$totalbases*100;
      $percg=$countg/$totalbases*100;
      $percc=$countc/$totalbases*100;
   }


   #Determine overall statistics for all contigs
   my $percgc=$percc+$percg;
   my $meanlength=$totalbases/$contignumber;
   my $meanerror=$totalerror/$contignumber;
   my $meanphred=$totalphred/$contignumber;
   my $meanreads=$totalreads/$contignumber;
   print OUTFILE ">>Number of Contigs:\n>$contignumber\n";
   print OUTFILE ">>Average length of contig:\n>",int($meanlength),"\n";
   print OUTFILE ">>Total number of bases:\n>$totalbases\n";
   print OUTFILE ">>Percent gc:\n>",int($percgc),"\n";
   print OUTFILE ">>Total error:\n>",int($totalerror),"\n";
   print OUTFILE ">>Mean error\n>",int($meanerror),"\n";
   print OUTFILE ">>Number of contigs with error rate less than or equal to 0.200:\n>$gooderror\n";
   print OUTFILE ">>Mean average phred score for Contigs:\n>",int($meanphred),"\n";
   print OUTFILE ">>Number of Contigs with average phred score greater than or equal to 70\n>$goodphred\n";
   print OUTFILE ">>Average number of reads per contig:\n>",int($meanreads),"\n";
   my %basecomposition=('a',$perca,'t', $perct,'g', $percg,'c', $percc,'gc', $percgc);

close OUTFILE;
return 1;
}
 
#------------------------------------------------------------------------
sub get_oneContig_from_Ace{

    # get ace file
    my $ace_file = shift;
    my $contig_no = shift;
    open(ACE,$ace_file);
    # get contig info
    my %contig;

    while (<ACE>){
	my $current_contig_number;
	my $sequence;
	my $qualities;
	if ($_=~/CO\sContig($contig_no)\s+(\d+)\s+(\d+)/){
	    $current_contig_number = $1;
	    $contig{$1}{'total_length'}=$2;
	    $contig{$1}{'reads'}=$3;
	    $_=<ACE>;
	    until ($_=~/BQ/){ 
		chomp $_;
		$sequence .= $_;  
		$_=<ACE>;
	    }
	    $_=<ACE>;
	    until ($_=~/AF/){ 
		chomp $_;
		$qualities .= $_;  
		$_=<ACE>;
	    }
	    
	    #remove all the pads globally from the sequence
	    $sequence=~s/\*//g;
	    $contig{$current_contig_number}{'sequence'}=$sequence;
	    @{$contig{$current_contig_number}{'contig_qualities'}}=split(" ",$qualities);
	    my ($err,$phred);
	    ($err,$phred) = GetErrRate(\@{$contig{$current_contig_number}{'contig_qualities'}});
	    $contig{$current_contig_number}{'error_rate'}=sprintf "%.2f", $err;
	    $contig{$current_contig_number}{'average_phred'}=$phred;
	    last;
	}
    }
    return \%contig;
}

#------------------------------------------------------------------------
sub GetErrRate{

    my $BQ=shift;
    my $err;
    my $err10kb;
    my $pesum;
    my $total_bq;
    my $count=0;

    foreach my $bq (@$BQ){
	$total_bq+=$bq;
	$count++;
        my $pe=10**($bq/-10);
        $pesum+=$pe;
    }
    my $avgphred = $total_bq / $count;
    $avgphred = sprintf "%0.0f", $avgphred;

    my $bps = $#$BQ+1;
    if ($bps == 0){
	return 0;
    }
    $err = $pesum/($bps);
    $err10kb = $err*10000;
    return $err10kb,$avgphred;
}   

#------------------------------------------------------------------------
#sub AnalyseRead{
#    my $curr_read = shift;
#    my $read_orientation=shift;
#    my $contig_orientation=shift;
#    my $location = shift;
#    my $read_length = shift;
#    my $sequence_length=shift;
#    my $start_site;
#    my $leeway = 30; #because approx. this much of the transposon is read.
#    if ($read_orientation eq $contig_orientation){
#	if ($location < 0){
#	    $start_site = -1;
#	}else{
#	    $start_site = $location + $leeway;
#	}
#    }elsif ($read_orientation ne $contig_orientation){
#	if ($location < 0){
#	    $start_site = $location + $read_length - $leeway;
#	}else{
#	    $start_site = $location + $read_length - $leeway; 
#	    if ($start_site > $sequence_length){
#		$start_site = -1;
#	    }
#	}
#    }
#    if ($start_site > 0){
#	#print "$curr_read\t$location\t$read_orientation\t$start_site\n";
#    }
#    return $start_site;
#    
#}

# round to the nearest integer
sub round { $_[0] > 0 ? int $_[0] + 0.5 : int $_[0] - 0.5 }

1;
