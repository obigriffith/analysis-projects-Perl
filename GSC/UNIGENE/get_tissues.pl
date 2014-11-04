#!/usr/local/bin/perl 
# Yaron Butterfield
# Analysis to extract tissues...
use lib "/home/ybutterf/perl/lib";
use ncbi;
use strict;
use Data::Dumper;

my $mgc_unigene_file = "/home/ybutterf/MGC/unigene/human_genes_missing_from_MGC.csv";
my $tissues = ncbi::parse_unigenefile($mgc_unigene_file);

foreach my $uni (keys %$tissues){
    print "$uni\t$tissues->{$uni}\n";
}

my $libraryfile = "/home/ybutterf/MGC/Source_Libraries/all_lib.txt";
my $libs = ncbi::get_libs($libraryfile);

#print Dumper($libs);
#exit;

foreach my $k (keys %$libs){
    my $data = $libs->{$k}{data};
    foreach my $i (keys %$data){
	print "$i,$data->{$i}\n";
    }
print "\n";
}

foreach my $uni (keys %$tissues){
    print "\n\n\n$uni";
    my $matches_libs = &search_mgc_tissues($tissues->{$uni});
    print Dumper($matches_libs);
}


exit;

sub search_mgc_tissues{
    my $tissues=shift;
    my @libs;
    foreach my $uni_tissue (@$tissues){
	foreach my $k (keys %$libs){
	    my $data = $libs->{$k}{data};
	    if (exists $data->{TISSUE}){
		if($uni_tissue=~/$data->{TISSUE}/){
		    # tissue matching
		    print "\n$uni_tissue <-> \t$data->{ORGAN}\t$data->{TISSUE}";
		    push(@libs,$data->{ID});
		}
	    }
	}
    }
    return \@libs;
}

