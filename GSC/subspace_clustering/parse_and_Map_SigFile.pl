#!/usr/bin/perl -w

use strict;
use Data::Dumper;

use Getopt::Std;
getopts("f:g:d:o:m:s:u:le");
use vars qw($opt_f $opt_g $opt_d $opt_o $opt_l $opt_m $opt_e $opt_s $opt_u);

#Unless the minimum options are provided, print usage documents and exit
unless ($opt_f && $opt_g && $opt_d){&printDocs;}

my %Data;

if ($opt_o){
  my ($geneclusterfile, $expclusterfile);
  $geneclusterfile = "$opt_o"."_genes.txt";
  $expclusterfile = "$opt_o"."_exps.txt";
  open (GENECLUSTERS, ">$geneclusterfile") or die "can't open $geneclusterfile\n";
  open (EXPCLUSTERS, ">$expclusterfile") or die "can't open $expclusterfile\n";
}

if ($opt_s){
  open (NEWSIGFILE, ">$opt_s") or die "Can't open $opt_s\n";
}

if ($opt_u){
  open (UPDATEFILE, ">$opt_u") or die "Can't open $opt_u\n";
}

my %genemap;
if ($opt_m){ #If specified, read in map file.  Expecting two columns, tab-delimited of form: id_to_map\tmapped_id
  my $mapfile = $opt_m;
  open (MAPFILE, $mapfile) or die "can't open $mapfile\n";
  while(<MAPFILE>){
    if ($_=~/(\S+)\s+(\S+)/){
      $genemap{$1}=$2;
    }
  }
}

open (SIGFILE, $opt_f) or die "can't open $opt_f\n";

my $i=0;
my ($genes, $dimensions, $cluster, $num_genes, $num_dimensions, $header_info);
my $headerlines=0;
while (<SIGFILE>){
  my $line=$_;
  #Grab header information
  unless($headerlines==1){
    $header_info.=$line;
    if ($line=~/\-\-\-\-\-\-\-\-/){ #Once a series of dashes seen, stop grabbing header info.
      $headerlines=1;
    }
    next;
  }
  chomp $line;
  #Proces each cluster
  if ($line=~/[Cc]luster\s(\d+)\:\s(\d+)\sgenes\sshare\s(\d+)\sdimensions/){
    $cluster=$1; $num_genes=$2; $num_dimensions=$3;
    #print "Cluster:$cluster\tGenes:$num_genes\tDimensions:$num_dimensions\n";
    $i++;
    next;
  }
  if ($i==1){
    $dimensions=$line;
    $i++;
    next;
  }
  if ($i==2){
    $genes=$line;
    $Data{$cluster}{'num_genes'}=$num_genes;
    $Data{$cluster}{'num_dimensions'}=$num_dimensions;
    $Data{$cluster}{'genes'}=$genes;
    $Data{$cluster}{'dimensions'}=$dimensions;

    #go through each gene in the list, map (if requested), and then create a unique gene list
    my @genelist;
    my @unmapped_genelist = split ("\t",$genes);

    #If genes need to be mapped, do it now
    if ($opt_m){
      my @mapped_genelist;
      foreach my $gene (@unmapped_genelist){
	if ($genemap{$gene}){ #check to see if gene is mapped
	  my $mapped_gene=$genemap{$gene};
	  #print "found_gene_mapping: $gene to $mapped_gene\n";
	  push (@mapped_genelist, $mapped_gene);
	}else{
	  next;
	}
      }
      unless (scalar(@mapped_genelist)>0){ #If no genes were successfully mapped, just skip to the next cluster
	print "No Genes could be mapped for cluster: $cluster\n";
	$Data{$cluster}{'num_uniq_genes'}=0;
	next;
      }
      @genelist=@mapped_genelist;
    }else{
      @genelist=@unmapped_genelist;
    }

    #In some cases, the genes in a cluster may be non-unique (because of mapping issues)
    foreach my $gene (@genelist){
      $Data{$cluster}{'uniqgenes'}{$gene}++;
    }
    $Data{$cluster}{'num_uniq_genes'}=keys %{$Data{$cluster}{'uniqgenes'}};
    $i=0;
    next;
  }
}

close SIGFILE;

foreach my $cluster (sort{$a<=>$b} keys %Data){
  if ($Data{$cluster}{'num_uniq_genes'} >= $opt_g && $Data{$cluster}{'num_dimensions'}>=$opt_d){
    print "cluster: $cluster genes: $Data{$cluster}{'num_genes'} unique genes: $Data{$cluster}{'num_uniq_genes'} dimensions: $Data{$cluster}{'num_dimensions'}\n";
    my @uniqgenes=keys %{$Data{$cluster}{'uniqgenes'}};
    if ($opt_o){
      if ($opt_l){
	if ($opt_e){
	  print GENECLUSTERS "cluster","$cluster\t","$Data{$cluster}{'num_dimensions'}\t",join("\t", @uniqgenes),"\n";
	  print EXPCLUSTERS "cluster"."$cluster\t","$Data{$cluster}{'num_uniq_genes'}\t"."$Data{$cluster}{'dimensions'}\n";
	}else{
	  print GENECLUSTERS "cluster","$cluster\t",join("\t", @uniqgenes),"\n";
	  print EXPCLUSTERS "cluster"."$cluster\t"."$Data{$cluster}{'dimensions'}\n";
	}
      }else{
	print GENECLUSTERS join("\t", @uniqgenes),"\n";
	print EXPCLUSTERS "$Data{$cluster}{'dimensions'}\n";
      }
    }
  }
}

#For sigfile option (recreates sigfile in old format but with mapping)
if ($opt_s){
  print NEWSIGFILE $header_info;
  foreach my $cluster (sort{$a<=>$b} keys %Data){
    if ($Data{$cluster}{'num_uniq_genes'} >= $opt_g && $Data{$cluster}{'num_dimensions'}>=$opt_d){
      my @uniqgenes=keys %{$Data{$cluster}{'uniqgenes'}};
      print NEWSIGFILE "cluster $cluster: $Data{$cluster}{'num_uniq_genes'} genes share $Data{$cluster}{'num_dimensions'} dimensions\n";
      print NEWSIGFILE "$Data{$cluster}{'dimensions'}\n";
      print NEWSIGFILE join("\t", @uniqgenes),"\n\n";
    }
  }
  close NEWSIGFILE;
}

#For updated sigfile option (recreates sigfile in new KiWi 1.0 format)
if ($opt_u){
  print UPDATEFILE $header_info;
  my $cluster_count=0;
  foreach my $cluster (sort{$a<=>$b} keys %Data){
    $cluster_count++;
    if ($Data{$cluster}{'num_uniq_genes'} >= $opt_g && $Data{$cluster}{'num_dimensions'}>=$opt_d){
      my @dimensions = split("\t", $Data{$cluster}{'dimensions'});
      my @uniqgenes=keys %{$Data{$cluster}{'uniqgenes'}};
      print UPDATEFILE "Cluster_$cluster_count: # of rows($Data{$cluster}{'num_uniq_genes'}); # of columns($Data{$cluster}{'num_dimensions'}); rows(",join(",", @uniqgenes),"); columns(",join(",",@dimensions),");\n";
    }
  }
  close UPDATEFILE;
}

if ($opt_o){
  close GENECLUSTERS;
  close EXPCLUSTERS;
}

sub printDocs{
print "Must supply file name and minimum number of genes/dimensions for subspace cluster. 
For output use -o, -s or -u depending on format desired.
Usage: parse_and_Map_SigFile.pl -l -e -g 2 -d 10 -f Kiwi_output.sig -m mapfile.txt -o output_base_name
Options:
-f path to KiWi sigfile
-g minimum number of unique genes allowed for a cluster to be output
-d minimum number of dimensions/experiments allowed for a cluster to be output
-l adds cluster names to output files 
-m allows a mapping file to be specified (expecting two columns, tab-delimited of form: \"id_to_map\tmapped_id\")
-e adds number of dimensions/experiments to gene cluster output and number of genes to experiment cluster output
-o path and base name for output files
-s path and name for new sig file output (useful if you want to map clusters but keep sigfile format (note header information copied not updated)
-u path and name for updated sigfile (using new KiWi 1.0 format)

Output:
_genes.txt file:
cluster_id\tnum_dimensions\tgeneA\tgeneB\t... (note: cluster_id and num_dimensions are optional)

_exps.txt file:
cluster_id\tnum_genes\texpA\texpB\t... (note: cluster_id and num_genes are optional)

NOTE: Make sure to run dos2unix on KiWi sig files before parsing to remove windows characters.\n\n";
exit;
}

