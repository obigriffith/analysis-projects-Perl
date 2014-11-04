#!/usr/bin/perl

=head1 NAME

  	Create_GO_Associations.pl

=head1 SYNOPSIS
	
	Create_GO_Associations.pl <GO_Term_Depth> [Include_IEA]
	
=head1 ARGUMENTS

	 
  	GO_Term_Depth	Value: Positive integer starting at 0	
					Specifies the level of GO term associations that will be built 
					for each gene. For example, 0 - specific GO term annotations, 1 - includes 
					specific GO term annotations and annotations to parent GO terms of 
					specific GO term annotations. 	
  			
 	Include_IEA		Value: N
					If specified, will not include electronically inferred annotations (IEA)
					in the GO associations file.
  			
=head1 DESCRIPTION
	
	Builds the Gene Annotation file for the GO Analyis process.

=head1 AUTHOR

  	D.L.Fulton
  	Simon Fraser University
  	E-mail: dlfulton@sfu.ca

=cut

use DBI;
use strict;

use constant VERSION 	=> "Create_GO_Associations.pl 1.0";
use constant DEBUG 		=> 0;
use constant USAGE 		=> "Create_GO_Associations.pl <GO_Term_Depth Value:Postive Integer> [Include_IEA Value:N] \n";
 
$| = 1;

my %child_parent_hash = ();
my @prtstring;
my $prtidx = 0;
my $GO_Term_Depth;
my $parent_termid;

## Database connection parameters
#my $dbname='goassoc'; 
#my $dbuser='root'; 
#my $dbpwd = ""; 
#my $mysqlhost='localhost'; 
my $mysqlv = 'mysql'; 

### GO database at the GSC
my $mysqlhost='db01';
#my $dbname='test_go_assoc_db'; 
my $dbname='GO_200407_assocdb';
my $dbuser='viewer'; 
my $dbpwd = 'viewer';
 
my $ref_id;
my $parent_id;
my $parent_acc;
my %uniprotid_by_locuslinkid;

#Process the arguments
if (scalar @ARGV < 1) {die ("\n ERROR: " .  USAGE . "\n");}

my $GO_Term_Depth = $ARGV[0];
my $Include_IEA = $ARGV[1];

 

if (($GO_Term_Depth < 0) || ($Include_IEA && $Include_IEA ne "N") ) 
    {die ("\n ERROR: " .  USAGE . "\n");}


my $starttime = time;
## Database handle
print "Connecting to mysql database...\n" if DEBUG;
my $dbh = DBI->connect("DBI:$mysqlv:$dbname:$mysqlhost", $dbuser, $dbpwd);

print "Connected to mysql database...\n" if DEBUG;

# Setup standard output files
open(NF, ">PopulationGeneAssoc") ||  
	die ("Can't open PopulationGeneAssoc: $!\n");
open(EXP, ">PopulationGeneAssocEXCEPTIONS") ||  
	die ("Can't open PopulationGeneAssoc: $!\n");

#-------------------------------- MAIN ---------------------------------------
&Build_Locuslink_XREF();	
&get_gene_GOterms();

my $endtime = time;
my $elapsed_time = $endtime - $starttime;
printf "***** Execution Time for this program: %7.3f minutes", $elapsed_time/60;
close(NF);
close(EXP);
exit 0;

#@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@  SUBROUTINES @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
sub get_gene_GOterms {
 
   	my $totalproduct = 0;
   	my $sth;   
   	my $sth1;
   	my $uniprot_id;
   	my $locuslink_id;
   	my $prtstring;
   	my $Uniprot_GOannot_found = 0;
   	my $childterm;
   	my %product_term_hash = (); 
   	my $uniprot_id_comp;
   	my $arraylength = 0;
   	my @uniprot_arr;
   	my @uniprot_term_arr;
   	my $i = 0;
  

 	# 
   	print "preparing product query  ...\n" if DEBUG;
   	if ($Include_IEA eq 'N') {
     	print "Non IEAs will be included\n";
    	$sth = $dbh->prepare(
    	" SELECT DISTINCT dbxref.xref_key, term.acc, term.id, gene_product.id " . 
       	"FROM " . 
       	"dbxref " .
       	"INNER JOIN " .
      	"gene_product ON (dbxref.id = gene_product.dbxref_id) " .
      	"INNER JOIN " .
       	"association ON (association.gene_product_id = gene_product.id) " .
      	"INNER JOIN " .
      	"term ON (association.term_id = term.id) " .
       	"INNER JOIN " .
       	"evidence ON (association.id = evidence.association_id) " .
       	"WHERE " .      
           
       	"dbxref.xref_dbname = 'UniProt' " .
    	"AND term.term_type = 'biological_process' " .  
       	"AND term.is_root = '0' " .  
       	"AND evidence.code != 'IEA' " . 
      	"ORDER BY dbxref.xref_key "
       	);
      	}
     else {   # include IEA GO terms
      	print "IEAs will be included\n";
       	$sth = $dbh->prepare(
       	" SELECT DISTINCT dbxref.xref_key, term.acc, term.id, gene_product.id " . 
       	"FROM " . 
       	"dbxref " .
       	"INNER JOIN " .
       	"gene_product ON (dbxref.id = gene_product.dbxref_id) " .
       	"INNER JOIN " .
      	"association ON (association.gene_product_id = gene_product.id) " .
       	"INNER JOIN " .
       	"term ON (association.term_id = term.id) " .
       	"INNER JOIN " .
       	"evidence ON (association.id = evidence.association_id) " .
       	"WHERE " .      
           
       	"dbxref.xref_dbname = 'UniProt' " .
       	"AND term.term_type = 'biological_process' " .  
       	"AND term.is_root = '0' " .             
       	"ORDER BY dbxref.xref_key "
      	);
   	}   
    print "sql product preparation is complete ...\n" if DEBUG;
    print "executing product query ...\n" if DEBUG;
    $sth->execute();
    print "product query completed...\n" if DEBUG;
       
    while (my @results = $sth->fetchrow_array()) {
    	$results[0] =~ /(\S+)/;
    	$uniprot_id = $1;
   		$results[2] =~ /(\S+)/;
    	$parent_id = $1;
   		$results[1] =~ /(\S+)/;
   		$parent_acc = $1; 
      	if ($uniprot_id_comp ne $uniprot_id && $parent_acc ne 'GO:0000004' && $parent_acc ne 'GO:0008150') {
       		$uniprot_id_comp = $uniprot_id;
         	$product_term_hash{$uniprot_id} = $i;  # this is the starting uniprot_id index in the array
           	}
   		### skip root, root biological process sub-tree and biological process unknown
       	if ($parent_acc ne 'GO:0000004' && $parent_acc ne 'GO:0008150') {
          	$uniprot_arr[$i] = $uniprot_id;
           	$uniprot_term_arr[$i] = $parent_acc;
           	$i++;
        }
	} # end while
      	
  	$arraylength = $#uniprot_arr;   
    #
   	print "Preparing child term query...\n" if DEBUG;
   	$sth1 = $dbh->prepare(
  	"SELECT DISTINCT " .
   	"child.id, child.name, child.term_type, child.acc, " . 
   	"parent.acc " .          
  	"FROM " .  
   	"term as parent, " .
   	"term2term, " .
   	"term as child " .
                
   	"WHERE " .   
 	"parent.id = term2term.term1_id AND " .
   	"parent.is_root = '0' AND " . 
   	"child.is_root = '0' AND " .   
   	"child.id  = term2term.term2_id AND " .
   	"child.term_type = 'biological_process' " 
             
   	);
       	
   	print "Executing child term query...\n" if DEBUG;	
   	$sth1->execute();
   	print "Child term query executed...\n if DEBUG";
          
   	while (my @results2 = $sth1->fetchrow_array()) {
               
    	$parent_acc =  $results2[4];
      	my $child_acc = $results2[3];
	
      	push(@{$child_parent_hash{$child_acc} }, $parent_acc);  # add to a hash of arrays
  
   	} # end while
         
   	# Read the Gene Set and extract the GO associations from the hash tables
    open INFILE, "PopulationGeneSet" || die "Can't open file:$!\n";

    while (<INFILE>) {
        
		chomp();
		my $infile_line = $_;	
		$infile_line =~ s|\s*(\S+)\s*|$1|g;
		print PR "-" x 70 . "\n" if DEBUG;
		print PR "line = $infile_line \n" if DEBUG;
		$locuslink_id = $infile_line;
        
    	print "locuslink_id->$locuslink_id\n" if DEBUG;
        $uniprot_id = &Conv2Uniprotid($locuslink_id);
    	print "uniprot_id->$uniprot_id\n" if DEBUG;
          
        if (defined($product_term_hash{$uniprot_id})) {
          
          	print NF "$locuslink_id \t";
           	$i = $product_term_hash{$uniprot_id};
           	$prtidx = 0; 
           	while ($uniprot_id eq $uniprot_arr[$i] && $i <= $arraylength) {
               
          		my $specific_term_acc = $uniprot_term_arr[$i];
         		$parent_termid = $specific_term_acc . '  '.' ;' ;
           		$prtstring[$prtidx] = $specific_term_acc;
               
           		&Get_Ancestors($specific_term_acc, $GO_Term_Depth);
             
           		$prtidx++;       
           		$i++;	
      		} # end while
 	
      		&Print_GO_Terms;   # Print the GO terms for the gene
              
      	} # end if
       	else {
          	print EXP "Locuslink_id: $locuslink_id \t UniProt_id: $uniprot_id \t annotation " .
                  "not found in GO BP\n";
      	} # end else
       
  	} # end while        
			
    
}
#-------------------------------------------------------------------------------------------
# Recursively extract and print ancestor terms for a most 'specific' term annotation.
# The $depth value determines the level of ancestors terms to include
sub Get_Ancestors ($$) {
    my $childterm = shift;
    my $depth = shift;
    
    if ($depth == 0)
       {return;}
   	else
    	{$depth = $depth - 1;
   		if (defined($child_parent_hash{$childterm})) {
         	my @ancestor_terms = @{$child_parent_hash{$childterm }};
          	my $arraylen = $#ancestor_terms;
           
          	for (my $j = 0; $j <= $arraylen; $j++) {
             	if (!(Duplicate_GO_Term($ancestor_terms[$j]))) {
                   	$prtidx++;
                   	$prtstring[$prtidx] = $ancestor_terms[$j];
               	} 
              	Get_Ancestors($ancestor_terms[$j], $depth); 
         	} # end for   
      	} # end if
  	}  # end else        
            
}
#-------------------------------------------------------------------------------------------
# Determines whether a GO Term is found in the print string.
# If found, returns a 1 (TRUE), otherwise returns a 0 (FALSE)
sub Duplicate_GO_Term($) {
   	my $GO_term = shift;
     
    my $found = 0;
    for (my $p = 0; $p <$prtidx; $p++) {
       	if ($prtstring[$p] eq $GO_term) {
            $found = 1;
        }
    }
    return $found;
}
#-------------------------------------------------------------------------------------------
# Prints the GO terms for one locus link gene id

sub Print_GO_Terms() {
    
    
    my $printstring = ();
     
    for (my $p = 0; $p <$prtidx; $p++) {     
    	$printstring = $printstring . $prtstring[$p] . '  '.' ;' ;
           
    }
    print (NF ($printstring, "\n")); 
}
#-------------------------------------------------------------------------------------------
# Converts Uniprot id to Locuslink id
sub Conv2Uniprotid () {
    my $locuslink_id = shift;
  
    if ($uniprotid_by_locuslinkid{$locuslink_id}) {
     	return $uniprotid_by_locuslinkid{$locuslink_id};
   	}
    else {
      	print "uniprot_id for locuslink_id : $locuslink_id not found\n" if DEBUG;
       	return;
   	}
    
}

#-------------------------------------------------------------------------------------------------------
#Builds the locuslink hash using EBI human xref file
#Also builds a uniprod id/locuslink id cross-reference file
#for testing.
#URL: ftp://ftp.ebi.ac.uk/pub/databases/GO/goa/HUMAN/
sub Build_Locuslink_XREF {

 	open INFILE, "xrefs.goa" || die "Can't open file:$!\n";
    open(XF, ">mylocuslink_uniprotxref ") ||  
	die ("Can't open myuniprot_locuslink_xref: $!\n");

    my $i = 0;
    while (<INFILE>) {
	 
	chomp();
	my @fields = split (/\t/, $_);
	
    	my @locus = split(/,/, $fields[9]);
        
        if ($locus[0] != " ") {
	   		print XF "$locus[0] \t $fields[1]\n";
          	$uniprotid_by_locuslinkid{$locus[0]} =  $fields[1];
       	}
         
	
    }

print "locus link hash table built ... \n" if DEBUG;
close(INFILE);
    
}





