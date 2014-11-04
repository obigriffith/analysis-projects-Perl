#!/usr/bin/perl -w

use strict;

$/="------------";

while (<>){
  if ($_=~/Epstein/){
    print $_;
  }
}
