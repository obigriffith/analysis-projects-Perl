#!/usr/bin/perl -w

#####################################################################
# file matrix.pl
# example implementation of SAGE tag ratio transformation algorithm
# smckay@bcgsc.bc.ca Sept 26/2003
#
# usage ./matrix.pl min_quality sig_level lib_list_file
#####################################################################

use DBI;
use strict;
use Data::Dumper;

# example library list and parameters
my $qual = $ARGV[0]; # need quality to be able to be 0!
my $sig  = $ARGV[1];
#y $lib_file = $ARGV[2];
open (FILE, $ARGV[2]) || die "Cannot open lib list file $ARGV[2]\n";

my @libs;
while (<FILE>) {
    chomp;
    push(@libs, $_);
}

my %seen = ();
my %size = ();
my @tags = ();
my %tags = ();
my %sigt = ();
my $freq = {};
my $count = {};

# get the tags lists
map { $tags{$_} = get_tags($_, $qual) } @libs; #populates @tags as well, just a list of all tags

print STDERR "Got all tags\n";

# process each library
for ( @libs ) {
    my @ltags = @{$tags{$_}};
    $size{$_} = @ltags;

    # get the counts
    print STDERR "getting counts for $_\n";
    $count->{$_} = count_tags(@ltags);

    # convert counts to frequencies
    print STDERR "getting freqs for $_\n";
    $freq->{$_} = count2freq($_);
}

# calculate the ratios
# and 'weight vector'
#First print title line
print 'Tag,', (join ',', &do_comps), "\n";

for my $tag ( @tags ) {
    my @ratio   = do_ratios($tag);
    my @weight  = do_stats($tag);
    my @results = ();
    
    die "Something is wrong! $tag" unless @ratio == @weight;

    for ( 1..@ratio ) {
	my $i = $_ - 1;
        push @results, ( $ratio[$i] * $weight[$i] );    
    }
    
    for ( @results ) {
        s/-0/0/;
    }
    #print results
    print $tag, ',', (join ',', @results), "\n";
}


#### Subroutines #####

sub count2freq {
    my $lib = shift;
    my %freq = ();
    for ( @tags ) {
	    $freq{$_} = $count->{$lib}->{$_} / $size{$lib};
    }

    \%freq;
}

sub do_ratios {
    my $tag = shift;
    my @ratios = ();
    my ($i, $j);
    for ( $i = 0; $i < @libs; $i++ ) { 
        for ( $j = $i + 1; $j < @libs; $j++ ) {
	    my $c1 = $freq->{$libs[$i]}->{$tag};
            my $c2 = $freq->{$libs[$j]}->{$tag};
            push @ratios, log2_ratio($c1, $c2);
        }
    }
    
    @ratios;
}

sub do_stats {
    my $tag = shift;
    my @weights = ();
    my ($i, $j);
    for ( $i = 0; $i < @libs; $i++ ) {
	for ( $j = $i + 1; $j < @libs; $j++ ) {
	    my $c1 = $count->{$libs[$i]}->{$tag} - 1;
	    my $c2 = $count->{$libs[$j]}->{$tag} - 1;
	    my ($low, $high) = ac_test($libs[$i], $libs[$j], $c1);
	    push @weights, $c2 <= $low || $c2 >= $high ? 1 : 0;
	}
    }

    @weights;
}

sub do_comps {
    my @comps = ();
    my ($i, $j);
    for ( $i = 0; $i < @libs; $i++ ) {
	for ( $j = $i + 1; $j < @libs; $j++ ) {
            push @comps, "$libs[$i]/$libs[$j]";
	}
    }

    @comps;
}

sub ac_test {
    my ($l1, $l2, $freq) = @_;
    my $n1 = $size{$l1};
    my $n2 = $size{$l2};
    
    $freq ||= '0';
    my $result = $sigt{$l1 . $freq} || `winflat -value $freq -sig $sig} -diff $n1 $n2`;

    # no point doing this calulation every time!
    $sigt{$l1 . $freq} ||= $result;
    
    my ($low, $high) = $result =~ /$freq:\s+(\S+)\s+-\s+(\S+)/;
    print "ERROR: $low|$high\n" unless $low && $high;

    ($low, $high);
}

sub log2_ratio {
    my $r = $_[0] / $_[1];
    return log($r)/log(2);
}


sub get_tags {
    my ($lib, $qual) = @_;
    
    if ($lib =~ /^X/){
      $qual=0;
    }
    my $dsn  = "DBI:mysql:sage:db01"; #changed from "sagedog01" to "db01"
    my $db   = DBI->connect( "$dsn", 'viewer', 'viewer' ) or die "$DBI::errstr\n";

    my @where = ( "FK_Library__name='$lib'", 
                  "sequence != 'TCCCTATTAA'",
		  "sequence != 'TCCCCGTACA'", 
		  "quality >= $qual",
		  "CK\$duplicate_\$BOOLEAN__id = 2" );

    my $query = 'SELECT sequence FROM Tag WHERE ' . join ' AND ', @where;
    print STDERR "query $query\n";

    my $sth   = $db->prepare( $query ) or die "Query format error";
    $sth->execute or die "Query execution error";

    my @lib_tags = ();
    while ( my ($tag) = $sth->fetchrow_array ) {
        push @lib_tags, $tag;
        push @tags, $tag unless $seen{$tag};
	$seen{$tag} = 1;
#	print "Tag $tag lib $lib\n";
    }
    \@lib_tags;
}


sub count_tags {
    my @ltags = @_;
    my %count = ();
    
    map { $count{$_}++ } @ltags;
    
    # now apply a +1 correction for all known tags
    map { $count{$_} += 1 } @tags;
    
    \%count;
}
