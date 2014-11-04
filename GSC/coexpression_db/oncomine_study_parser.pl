#!/usr/local/bin/perl -w

# Define module to use
use HTML::Parser();

my @records;
my $name;
my $summary_file = "/home/obig/clustering/coexpression_db/Oncomine/study_summary.txt";
open (SUMMARY, ">$summary_file") or die "can't open $summary_file\n";

my @files = `ls /home/obig/clustering/coexpression_db/Oncomine/study_details/`;
foreach my $file (@files){
chomp $file;
  undef @records;
  my $outfile;
  $outfile="./study_details_parsed/"."$file.parsed";
  $file = "./study_details/"."$file";
#  print "$file\t$outfile\n";
  open (FILE, $file) or die "can't open $file\n";
  open (OUTFILE, ">$outfile") or die "can't open $outfile\n";

  # Create instance
  $p = HTML::Parser->new(start_h => [\&start_rtn, 'tag'],
                text_h => [\&text_rtn, 'text'],
		       end_h => [\&end_rtn, 'tag']);

  my $html = '';
  while (<FILE>){
    $html ="$html"."$_";
  }
  
  # Start parsing the following HTML string
  $p->parse($html);

  #parse record
  print "parsing record to: $outfile\n";
  my $i=0;
  foreach my $record (@records){
    print OUTFILE "$record\n";
  }
print SUMMARY "$records[3]\t$records[5]\t$records[7]\t$records[13]\t$records[15]\t$records[17]\t$records[19]\t$records[21]\n";
close FILE;
close OUTFILE;
}
exit;
sub start_rtn {
# Execute when start tag is encountered
    foreach (@_) {
#	print "===\nStart: $_\n";
    }
}
sub text_rtn {
# Execute when text is encountered
    foreach (@_) {
	my $line = $_;
	$line=~s/&nbsp;//g;
	if ($line=~/\S+/){
	    $line=~s/\n//g; #remove carriage returns
	    $line=~s/\t//g; #remove tabs
	    if ($line =~/^(\s+)(\w+.+)/){$line=$2;}
	    #print "$line\n";
	    push (@records, $line);
	}
#	print "\tText: $_\n";
    }
}

sub end_rtn {
# Execute when the end tag is encountered
    foreach (@_) {
#	print "End: $_\n";
    }
}

