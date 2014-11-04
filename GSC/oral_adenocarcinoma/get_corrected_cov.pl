#!/usr/bin/perl
use strict;
#my $genomic_total = 2385756324; #Number to be updated if analysis rerun.
my $genomic_total = 10536427104;

#my %correction = load_cor("/projects/rmorin/BP/WGS/HS0729_tumour/wtss_out/gene_expected_num_bases_t1000000.txt");
#my %correction = load_cor("/projects/rmorin/BP/WGS/HS0729_tumour/wtss_out/gene_expected_num_bases_t1000000_72lanes.txt");
my %correction = load_cor("/home/obig/Projects/oral_adenocarcinoma/solexa_data/maq_analysis/gene_expected_num_bases_t1000000_160lanes.txt");


while(<STDIN>){
    #ENSG00000127720 chr12   81276455        81397069        1968    15586   7.91971544715447
    #
    my @a = split;
    my $sequenced = $a[5];
    my $gene = $a[0];
    my $chr = $a[1];
    my $start = $a[2];
    my $end = $a[3];
    my $size = $a[4];
#    my $expected = $correction{$gene} * $genomic_total * 0.95/1000000;
    my $expected = $correction{$gene} * $genomic_total * 0.84/1000000; #Ryan's newer estimate of genomic contamination.
    my $corrected = $sequenced - $expected;
    if ($corrected<0){$corrected=0;} #If corrected value is negative, reset to 0
    my $cor_cov = $corrected/$size;
    #print "$gene\t$sequenced\t$expected\t$corrected\t$cor_cov\n";
    print "$gene\t$chr\t$start\t$end\t$size\t$corrected\t$cor_cov\n";
}

sub load_cor{
    my $file = shift;
    open F, $file or die "";
    my %correction;
    while(<F>){
	chomp;
	my ($g,$c) = split;
	$correction{$g} = $c;
    }
    return(%correction);
}
