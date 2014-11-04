#!/gsc/bin/perl

use warnings;
use strict;
use Genome;
use IO::File;

my $inFh = IO::File->new( $ARGV[0] ) || die "can't open file\n";
while( my $line = $inFh->getline )
{
    chomp($line);
    my @F = split("\t",$line);

    next if $line =~/^chromosome_name/;

    $F[3] =~ s/\*/-/g;

    #tabbed format - 1  123  456  A  T
    
    if (($F[3] =~ /0/) || ($F[3] =~ /\-/)){ #indel INS
        $F[2] = $F[2]-1;
        print join("\t",($F[0],$F[1],$F[2],$F[3],$F[4]));

    } elsif (($F[4] =~ /0/) || ($F[4] =~ /\-/)){ #indel DEL
        $F[1] = $F[1]-1;
        print join("\t",($F[0],$F[1],$F[2],$F[3],$F[4]));

    } else { #SNV
        $F[1] = $F[1]-1;
        print join("\t",($F[0],$F[1],$F[2],$F[3],$F[4]));
    }

    if(@F > 4){
        print "\t" . join("\t",@F[5..$#F])
    }
    print "\n";

}
close($inFh);
