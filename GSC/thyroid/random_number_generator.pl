#!/usr/bin/perl -w

use strict;

srand(time() ^($$ + ($$ <<15))) ;

my $n = 50;
my $max = 50;
my @rand_numbers;
my $i;

for ($i=0; $i<$n; $i++){
  my $rand_number = int(rand($max));
  push (@rand_numbers,$rand_number);
}

print join(",",@rand_numbers),"\n";

