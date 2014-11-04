#!/usr/bin/perl
use strict;
use warnings;
use Data::Dumper;

my $working_dir = "/gscmnt/sata132/techd/mgriffit/braf_resistance/report2/bam_readcounts_all_bams/";

#Get the SNV positions to be summarized
my %snvs;
my $snv_file = $working_dir . "BRAF_Master_SNV_List.tsv";
open (SNV, "$snv_file") || die "\n\nCould not open file: $snv_file";
my $header = 1;
while(<SNV>){
  chomp($_);
  my @line = split("\t", $_);
  my $coord = $line[0];
  if ($header){
    $header = 0;
    next;
  }

  $snvs{$coord}{gene_name} = $line[1];
  $snvs{$coord}{mapped_gene_name} = $line[2];
  $snvs{$coord}{ensembl_gene_id} = $line[3];
  $snvs{$coord}{aa_changes} = $line[4];
  $snvs{$coord}{ref_base} = $line[5];
  $snvs{$coord}{var_base} = $line[6];
}
close(SNV);

#NOTE.  It looks like bam-readcounts reports nothing if there is reads overlapping a region.  But if there are read pairs spanning the region but no actual coverage at the position a coverage of 0 may be reported 

#Get the bam-readcounts results for all cell lines both RNA and DNA
my %subject_list;
opendir(DIR, $working_dir);
my @files = readdir(DIR);
closedir(DIR);
foreach my $file (@files){
  next unless ($file =~ /bam\-readcounts\.txt/);
  my $subject;
  if ($file =~ /(.*)\.bam\-readcounts\.txt/){
    $subject = $1;
  }else{
    print "\n\nCould not resolve subject from file name: $file";
    exit();
  }
  chomp($file);
  my $path = $working_dir.$file;
  print "\nProcessing file: $path";

  open (BAMRC, "$file") || die "\n\nCould not open file: $file\n\n";
  while (<BAMRC>){
    chomp($_);
    my @line = split("\t", $_);
    next unless (scalar(@line) == 10);

    my $chr = $line[0];
    my $pos = $line[1];
    my $ref_base = $line[2];
    my $coverage = $line[3];
    my $a_string = $line[5];
    my @a_val = split(":", $a_string);
    my $a_count = $a_val[1];
    my $c_string = $line[6];
    my @c_val = split(":", $c_string);
    my $c_count = $c_val[1];
    my $g_string = $line[7];
    my @g_val = split(":", $g_string);
    my $g_count = $g_val[1];
    my $t_string = $line[8];
    my @t_val = split(":", $t_string);
    my $t_count = $t_val[1];
    
    my %bases;
    $bases{A}{count} = $a_count;
    $bases{C}{count} = $c_count;
    $bases{G}{count} = $g_count;
    $bases{T}{count} = $t_count;

    my $coord = "$chr:$pos-$pos";
    unless ($snvs{$coord}){
      print "\n\nFound bam-readcounts coord that is unexpected: $coord\n\n";
      exit();
    }

    my $var_base = $snvs{$coord}{var_base};
    my $ref_count = $bases{$ref_base}{count};
    my $var_count = $bases{$var_base}{count};
    my $vaf = 0;
    if ($coverage > 0){
      $vaf = ($var_count/$coverage)*100;
    }
    $vaf = sprintf("%.5f", $vaf);

    $snvs{$coord}{$subject}{coverage} = $coverage;
    $snvs{$coord}{$subject}{ref_count} = $ref_count;
    $snvs{$coord}{$subject}{var_count} = $var_count;
    $snvs{$coord}{$subject}{vaf} = $vaf;
    $subject_list{$subject}=1;
  }
  close (BAMRC);
}

my @subject_list = sort keys %subject_list;
my $subject_list = join("\t", @subject_list);

#Print out matrix files for coverage, ref_count, var_count, and vaf
open (COV, ">$working_dir/final_coverage_matrix.tsv") || die "\n\nCould not open file: $working_dir/final_coverage_matrix.tsv\n\n";
open (REF, ">$working_dir/final_refcount_matrix.tsv") || die "\n\nCould not open file: $working_dir/final_refcount_matrix.tsv\n\n";
open (VAR, ">$working_dir/final_varcount_matrix.tsv") || die "\n\nCould not open file: $working_dir/final_varcount_matrix.tsv\n\n";
open (VAF, ">$working_dir/final_vaf_matrix.tsv") || die "\n\nCould not open file: $working_dir/final_vaf_matrix.tsv\n\n";

my $header_line = "coord\tgene_name\tmapped_gene_name\tensembl_gene_id\taa_changes\tref_base\tvar_base\t$subject_list\n";
print COV $header_line;
print REF $header_line;
print VAR $header_line;
print VAF $header_line;

foreach my $coord (sort keys %snvs){
  my $gene_name = $snvs{$coord}{gene_name};
  my $mapped_gene_name = $snvs{$coord}{mapped_gene_name};
  my $ensembl_gene_id = $snvs{$coord}{ensembl_gene_id};
  my $aa_changes = $snvs{$coord}{aa_changes};
  my $ref_base = $snvs{$coord}{ref_base};
  my $var_base = $snvs{$coord}{var_base};
  my @coverage;
  my @ref_count;
  my @var_count;
  my @vaf;
  foreach my $subject (sort keys %subject_list){
    my $coverage = 0;
    my $ref_count = 0;
    my $var_count = 0;
    my $vaf = 0;
    $coverage = $snvs{$coord}{$subject}{coverage} if (defined($snvs{$coord}{$subject}));
    $ref_count = $snvs{$coord}{$subject}{ref_count} if (defined($snvs{$coord}{$subject}));
    $var_count = $snvs{$coord}{$subject}{var_count} if (defined($snvs{$coord}{$subject}));
    $vaf = $snvs{$coord}{$subject}{vaf} if (defined($snvs{$coord}{$subject}));
    push(@coverage, $coverage);
    push(@ref_count, $ref_count);
    push(@var_count, $var_count);
    push(@vaf, $vaf);
  }
  my $coverage_s = join("\t", @coverage);
  my $ref_count_s = join("\t", @ref_count);
  my $var_count_s = join("\t", @var_count);
  my $vaf_s = join("\t", @vaf);

  print COV "$coord\t$gene_name\t$mapped_gene_name\t$ensembl_gene_id\t$aa_changes\t$ref_base\t$var_base\t$coverage_s\n";
  print REF "$coord\t$gene_name\t$mapped_gene_name\t$ensembl_gene_id\t$aa_changes\t$ref_base\t$var_base\t$ref_count_s\n";
  print VAR "$coord\t$gene_name\t$mapped_gene_name\t$ensembl_gene_id\t$aa_changes\t$ref_base\t$var_base\t$var_count_s\n";
  print VAF "$coord\t$gene_name\t$mapped_gene_name\t$ensembl_gene_id\t$aa_changes\t$ref_base\t$var_base\t$vaf_s\n";

}

close(COV);
close(REF);
close(VAR);
close(VAF);


#print Dumper %snvs;

print "\n\n";

