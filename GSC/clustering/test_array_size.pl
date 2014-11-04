#!/usr/bin/perl

for ($i =0; $i<22000; $i++){
    for ($j=0; $j<70000; $j++){
	$array[$i][$j]=1;
    }
    print "row: $i\r";
}

exit;
