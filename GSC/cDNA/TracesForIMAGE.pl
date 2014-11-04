#!/usr/local/bin/perl

######################################################################
##
## Carl Schaefer
## National Cancer Institute, Center for Bioinformatics
## May 21, 2003
##
## Input: single-column list of IMAGE clone ids (numeric part only)
## Output: header lines from GenBank fasta format for accessions of clones
##
######################################################################

use strict;
use LWP::Simple;

use constant LENGTH    => 100;
use constant SLEEPTIME => 5;
my @image;

my $image = ReadInput();
my $gi    = GetGIsFromGenBank($image);
my $def   = GetDefLineFromGenBank($gi);

print join("\n", @{ $def }) . "\n";

######################################################################
sub ReadInput {

  my @image;
  while (<>) {
    chop;
    push @image, "\"IMAGE:$_\"";
  }
  return \@image;
}

######################################################################
sub GetGIsFromGenBank {
  my ($image)= @_;

  my (@gi, $list);

  for (my $i = 0; $i < @{ $image }; $i += LENGTH) {
    if(($i + LENGTH - 1) < @{ $image }) {
      $list = join("+OR+", @{ $image }[$i..$i+LENGTH-1]);
    }
    else {
      $list = join("+OR+", @{ $image }[$i..@{ $image }-1]);
    }
    my $url = "http://www.ncbi.nlm.nih.gov/entrez/eutils/esearch.fcgi?" .
              "db=nucleotide&" .
              "retstart=0&" .
              "retmax=1000000&" .
              "term=$list";
    for (split "\n", get($url)) {
      if(/<Id>(\d+)<\/Id>/) {
        push @gi, $1;
      }
    }   
  }
  return \@gi; 
}

######################################################################
sub GetDefLineFromGenBank {
  my ($gi)= @_;

  my (@def, $list);

  for (my $i = 0; $i < @{ $gi }; $i += LENGTH) {
    if(($i + LENGTH - 1) < @{ $gi }) {
      $list = join(",", @{ $gi }[$i..$i+LENGTH-1]);
    }
    else {
      $list = join(",", @{ $gi }[$i..@{ $gi }-1]);
    }
    my $url = "http://www.ncbi.nlm.nih.gov/entrez/eutils/efetch.fcgi?" .
            "db=nucleotide&" .
            "retstart=0&" .
            "retmax=1000000&" .
            "view=fasta&" .
            "id=$list";
    for (split "\n", get($url)) {
      if ( /^>gi/ ) {
        push @def, $_;
      }
    }
    sleep(SLEEPTIME);
  }

  return \@def;
}
