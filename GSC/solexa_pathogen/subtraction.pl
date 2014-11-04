#!/usr/bin/perl
#Rene Warren, April 2008


use strict;
use Data::Dumper;

my $config = "config.txt";
my $pipeline = "na";
my $mode = "serial";

if($#ARGV<2){die "Usage: $0 <query fasta> <base name for files> <serial/parallel> <optional --resume pipeline--- cdna, genome, interest, finish or clean\n";}
if(! -e $config){die "Error: can't find $config, make sure it is in your working directory -- fatal\n";}
if(! -e $ARGV[0]){die "Error: can't find file $ARGV[0] -- fatal\n";}

### Getting configuration information
my $conf;
open(CONFIG,$config);
while(<CONFIG>){
   chomp;
   my @a=split(/\;/);
   $conf->{$a[1]}=$a[2];
}
close CONFIG;

$pipeline = $ARGV[3] if ($ARGV[3] ne "");
$mode = "parallel" if ($ARGV[2] ne "serial");
my $dir = `pwd`;
chomp($dir);
my $base_job_name = $ARGV[1];
my $TIME_TO_WAIT = $conf->{'wait'};
my $log = $dir . "/qstat.txt";

if($pipeline eq "clean"){
   removeDataFromNodes($dir, $conf->{'headnode'});
   exit;  
}


### Launching the first job
my $base_name = "JS1";
my $screen = "cdna";
my $super_base_name = $base_job_name . $base_name;
my $jobdir = $dir . "/" . $screen;
my $sub1 = $ARGV[0] . ".cdna.submitted";
my $sub2 = $ARGV[0] . ".genome.submitted";
my $sub3 = $ARGV[0] . ".interest.submitted";
my $sub4 = $ARGV[0] . ".interest_unaligned.fa";
my $sub5 = $ARGV[0] . ".interest_aligned.fa";

eval{

if($pipeline eq "na" || $pipeline eq $screen){

   ###----------------------------------
   ### Split Original Input
   `rm -rf $jobdir`;
   `mkdir $jobdir`;
   my $first_file_input = &splitInput($ARGV[0],$jobdir,$conf->{'cluster_jobs1'},$sub1);

   my $db = $conf->{$screen};
   if(! -e $db){die "*$db* doesn't exist..check your input.\n";}
   my $db_name = $1 if ($db=~/([^\/]*)$/);

   print "Generating Shell Scripts...\n";
   my $job_files=&makeSS($conf->{'aligner'}, $conf->{'aligner_options1'}, $first_file_input,$jobdir, $super_base_name,$base_name,$db_name,$db,$mode);

   ### Execute jobs
   if($mode eq "parallel"){
      &executeJobs($job_files, $jobdir, $super_base_name, $conf->{'headnode'}, $conf->{'qsub'}, $conf->{'resource'});
      ### Monitor/wait for jobs to finish
      &monitorJobs($super_base_name, $log, $conf->{'headnode'}, $conf->{'qstat'});
   }else{
      foreach my $runfile (@$job_files){
         `chmod 755 $runfile`;
         my $cmd = "bash $runfile";
         print "Will Execute: $cmd\n";
         system($cmd);
      } 
   }
}

#------------------- extract unaligned sequences ----------
my $allout = $screen . ".out";
my $fasta_output = $screen . "-unaligned.fa";
`cat $jobdir/$super_base_name*.out > $allout`;

print "Will inspect $fasta_output...\n";

### Launching the second job
my $base_name = "JS2";
$screen = "genome";
$super_base_name = $base_job_name . $base_name;
my $jobdir = $dir . "/" . $screen;

die "File $allout is empty or missing; There might be some issues with $jobdir/$super_base_name* -- fatal\n" if (-z $allout);

if($pipeline eq "na" || $pipeline eq $screen){

   ###----------------------------------
   ### Split Secondary input (unaligned sequences from cdna)
   `rm -rf $jobdir`;
   `mkdir $jobdir`;
   my $second_file_input = &createFileSubset($sub1,$allout,$jobdir,$conf->{'cluster_jobs2'},$fasta_output,$sub2,$conf->{'regex1'});

   my $db = $conf->{$screen}; 
   if(! -e $db){die "*$db* doesn't exist..check your input.\n";}
   my $db_name = $1 if ($db=~/([^\/]*)$/);

   print "Generating Shell Scripts...\n";
   my $job_files=&makeSS($conf->{'aligner'}, $conf->{'aligner_options2'}, $second_file_input,$jobdir, $super_base_name,$base_name,$db_name,$db,$mode);

   ### Execute jobs
   if($mode eq "parallel"){
      &executeJobs($job_files, $jobdir, $super_base_name, $conf->{'headnode'}, $conf->{'qsub'}, $conf->{'resource'});
      ### Monitor/wait for jobs to finish
      &monitorJobs($super_base_name, $log, $conf->{'headnode'}, $conf->{'qstat'});
   }else{
      foreach my $runfile (@$job_files){
         `chmod 755 $runfile`;
         my $cmd = "bash $runfile";
         print "Will Execute: $cmd\n";
         system($cmd);
      }
   }
}

#------------------- extract unaligned sequences ----------

my $allout = $screen . ".out";
my $fasta_output = $screen . "-unaligned.fa";

print "Will inspect $fasta_output...\n";

`cat $jobdir/$super_base_name*.out > $allout`;
### Launching the third job
my $base_name = "JS3";
$screen = "interest";
$super_base_name = $base_job_name . $base_name;
my $jobdir = $dir . "/" . $screen;

die "File $allout is empty or missing; There might be some issues with $jobdir/$super_base_name* -- fatal\n" if (-z $allout);

if($pipeline eq "na" || $pipeline eq $screen){

   `rm -rf $jobdir`;
   `mkdir $jobdir`;
   my $third_file_input = &createFileSubset($sub2,$allout,$jobdir,$conf->{'cluster_jobs3'},$fasta_output,$sub3,$conf->{'regex2'});
   my $db = $conf->{$screen};
   if(! -e $db){die "*$db* doesn't exist..check your input.\n";}
   my $db_name = $1 if ($db=~/([^\/]*)$/);

   print "Generating Shell Scripts...\n";
   my $job_files=&makeSS($conf->{'aligner'}, $conf->{'aligner_options3'}, $third_file_input, $jobdir, $super_base_name,$base_name,$db_name,$db,$mode);

   ### Execute jobs
   if($mode eq "parallel"){
      &executeJobs($job_files, $jobdir, $super_base_name, $conf->{'headnode'}, $conf->{'qsub'}, $conf->{'resource'});
      ### Monitor/wait for jobs to finish
      &monitorJobs($super_base_name, $log, $conf->{'headnode'}, $conf->{'qstat'});
   }else{
      foreach my $runfile (@$job_files){
         `chmod 755 $runfile`;
         my $cmd = "bash $runfile";
         print "Will Execute: $cmd\n";
         system($cmd);
      }
   }

}

#--------------------concat final hits into a single file

my $allout = $screen . ".out";
my $fasta_output = $screen . "-unaligned.fa";
`cat $jobdir/$super_base_name*.out > $allout`;

#exit; ##remove

print "Will inspect $fasta_output...\n";

### Launching the fourth job
my $base_name = "JS4";
$screen = "finish";
$super_base_name = $base_job_name . $base_name;
my $jobdir = $dir . "/" . $screen;

die "File $allout is empty or missing; There might be some issues with $jobdir/$super_base_name* -- fatal\n" if (-z $allout);

if($pipeline eq "na" || $pipeline eq $screen){

   `rm -rf $jobdir`;
   `mkdir $jobdir`;
   my $third_file_input = &createFiles($sub3,$allout,$jobdir,$conf->{'cluster_jobs4'},$fasta_output,$sub4,$sub5,$conf->{'regex3'});

   exit;

   my $db = $conf->{$screen};
   if(! -e $db){die "*$db* doesn't exist..check your input.\n";}
   my $db_name = $1 if ($db=~/([^\/]*)$/);

   print "Generating Shell Scripts...\n";
   my $job_files=&makeSS($conf->{'aligner'}, $conf->{'aligner_options4'}, $third_file_input, $jobdir, $super_base_name,$base_name,$db_name,$db,$mode);

   ### Execute jobs
   if($mode eq "parallel"){
      &executeJobs($job_files, $jobdir, $super_base_name, $conf->{'headnode'}, $conf->{'qsub'}, $conf->{'resource'});
      ### Monitor/wait for jobs to finish
      &monitorJobs($super_base_name, $log, $conf->{'headnode'}, $conf->{'qstat'});
   }else{
      foreach my $runfile (@$job_files){
         `chmod 755 $runfile`;
         my $cmd = "bash $runfile";
         print "Will Execute: $cmd\n";
         system($cmd);
      }
   }

}

#--------------------concat final hits into a single file
my $allout = $screen . ".out";
my $fasta_output = $screen . "-unaligned.fa";
`cat $jobdir/$super_base_name*.out > $allout`;


};###end eval block

my $date = `date`;

if($@){
   my $message = $@;
   my $failure = "\nSomething went wrong running $0 $date\n$message\n";
   print $failure;
   print LOG $failure;
}else{
   my $success = "\nScript executed normally $date\n";
   print $success;
   print LOG $success;
}



exit;












#------------------------------------------------
sub removeDataFromNodes{

   my ($dir, $headnode, $qsub) = @_;
   
   my $jobdir = $dir . "/clean";
   `rm -rf $jobdir`;
   `mkdir $jobdir`;
   
   for(my $x=1;$x<=150;$x++){
      my $file = "cleanNodes" . $x . ".sh";
      open(CLEAN, ">$jobdir/$file");
      print CLEAN "#!/bin/sh\n";
      print CLEAN "#\$ -S /bin/sh\n";
      print CLEAN "#\$ -V\n";
      print CLEAN "rm -rf /tmp/*";
      close CLEAN; 
   }

   for(my $x=1;$x<=150;$x++){
      my $file = "cleanNodes" . $x . ".sh";
      my $qsub_cmd= "ssh $headnode 'export SGE_ROOT=/opt/sge;cd $jobdir;$qsub -pe ncpus 1 -N clean$x $file' ";
      system($qsub_cmd);
   }
}

#------------------------------------------------
sub createFileSubset{

   my ($original,$allout,$dir,$numjobs,$fasta_output,$sub,$regex) = @_;

   open(IN,$allout);
   ### Warning, will put lots of IDs in memory
   my $seen;
   while(<IN>){   
      chomp;
      my @a=split(/$regex/); ### could be in the config file to make it more generic / .
      $seen->{$a[1]}++;   ### could be in the config file to make it more generic / .
      #print "$a[1]\n";
   }
   close IN;

   open(OUT, ">$fasta_output");
   open(FA,$original);
   my $flag=0;
   while(<FA>){
      chomp;
      if(/\>(\S+)/){
         if(! defined $seen->{$1}){print OUT ">$1\n";$flag=1;}
      }else{
         print OUT "$_\n" if($flag);
         $flag=0;
      }   
   }
   close FA;
   close OUT;

   my $file_input = &splitInput($fasta_output,$dir,$numjobs,$sub);
   return $file_input;
}

#------------------------------------------------
sub createFiles{

   my ($original,$allout,$dir,$numjobs,$fasta_output,$sub1,$sub2,$regex) = @_;

   open(IN,$allout);
   ### Warning, will put lots of IDs in memory
   my $seen;
   while(<IN>){
      chomp;
      my @a=split(/$regex/);
      $seen->{$a[1]}++;
      #print "$a[1]\n";
   }
   close IN;

   open(OUT, ">$fasta_output");
   open(OUT2, ">$sub2");

   open(FA,$original);
   my $flag=0;
   while(<FA>){
      chomp;
      if(/\>(\S+)/){
         if(! defined $seen->{$1}){print OUT ">$1\n";$flag=1;}else{print OUT2 ">$1\n";}
      }else{
         if($flag){print OUT "$_\n"}else{print OUT2 "$_\n";}
         $flag=0;
      }
   }
   close FA;
   close OUT;
   close OUT2;

   my $file_input = &splitInput($fasta_output,$dir,$numjobs,$sub1);
   return $file_input;
}


#------------------------------------------------
sub executeJobs{

   my ($job_file, $jobdir, $super_base_name, $headnode, $qsub, $resource) = @_;

   my $job_count=0;

   foreach my $job_file(@$job_file){
      $job_count++;
      my $subjobname=$super_base_name . "." . $job_count;
      my $qsub_cmd= "ssh $headnode 'export SGE_ROOT=/opt/sge;cd $jobdir;$qsub $resource -N $subjobname $job_file' "; 
      print "$qsub_cmd\n";
      system($qsub_cmd);
      sleep(1);
   }
}

#------------------------------------------------
#Check status, wait until all sub jobs are done before resuming script
#The system call returns 0 or 1 depending on success or failure, respectively (yes 0==success!)
#I am not aware of other ways to capture the output generated by programs called by system, but to redirect the output to a file.
sub monitorJobs{

   my ($super_base_name, $log, $headnode, $qstat) = @_;

   my $flag=1;
   my @status;

   while($flag){

      print "There are still some jobs queued/running...will wait $TIME_TO_WAIT sec. jobs are $super_base_name*\n";
      sleep($TIME_TO_WAIT);
      my $qstat_cmd="ssh $headnode 'export SGE_ROOT=/opt/sge;$qstat > $log'";
      system($qstat_cmd);

      #`cat $log1 $log2 > $log`;
      #sleep(2);
      open (LOG, $log) || die "Can't open $log.\n";
      @status=<LOG>;
      close LOG;

      $flag=0; #reset flag
      foreach my $status_line(@status){
          if($status_line=~/$super_base_name/i){  ###this will capture only jobs related to this project
            $flag=1;
            print "$status_line\n";
         }
      }
   }

   print "All sub jobs of run $super_base_name have finished.\n";
}

#------------------------------------------
sub makeSS{

   my ($exec, $options, $file_input,$dir,$super_base_name,$base_name,$db_name,$db,$mode)=@_;   

   my @job_files;
   
   my $job_id=1;
   foreach my $input (@$file_input){

      my $output;
      my $tmp_output;  
 
      my $title;
      chomp($input);      

         my $input_fn;

         if ($input=~/([^\/]*)$/){
            my $filename=$1;
            $output = $dir ."/". $super_base_name . "." . $job_id . "_" . $db_name .".out";
            $tmp_output = "/tmp/" . $super_base_name . "." . $job_id . "_" . $db_name .".out";            

            $title = $filename . "_" . $db_name;
            $input_fn = $filename;
         }

         my $work_dir = "/tmp/" . $base_name . $job_id;
         my $work_all = $work_dir . "/*";
         my $new_in = $work_dir . "/" . $input_fn; 
         my $new_db = $work_dir . "/" . $db_name;
         
         my $job_file=$dir . "/" . $super_base_name . "." . $job_id . ".sh";

         push @job_files, $job_file;
         open (JOB, ">$job_file") or die "can't open $job_file for writing.\n";
         print JOB "#!/bin/sh\n";
         print JOB "#\$ -S /bin/sh\n";
         print JOB "#\$ -V\n";
         my $cmd1 = "rm -rf $work_all;rm -rf work_dir;mkdir $work_dir;cp -rf $db $work_dir;cp -rf $input $new_in;cd $dir;$exec $options $new_in $new_db > $tmp_output;cp -rf $tmp_output $output;rm -rf $work_all;rm -rf $work_dir\n";
         my $cmd2 = "$exec $options $input $db > $output\n";
         print JOB $cmd1 if($mode eq 'parallel');
         print JOB $cmd2 if($mode eq 'serial');
         close JOB;
         $job_id++;
   }

   return \@job_files;
}

#--------------------------------------------
sub splitInput{

   my ($fa,$dir,$numjobs,$submitted) = @_;

   ### Defining the number of entries in each job file
   my $count = `grep -c ">" $fa`;
   chomp($count);
   my $entries = int($count / $numjobs) + 1;

   ### splitting input fasta file
   print "There are $count entries in your input fasta file $fa.  Will split into $numjobs files each having ~$entries fasta entries.\n";

   open (OUT,$fa);

   my ($ct,$mod)=(0,1);

   my $modfa = $fa . "." . $mod;

   open (IN, ">$dir/$modfa");
   open (SU, ">$submitted");   

   my $head="";
   my $unique;
   my $lcr=0;
   my $dup = 0;
   my $tot = 0;

   while(<OUT>){
      chomp;
      if(/(\>\S+)/){
         $head=$1;
      }elsif(/([ACGTNX]*)/i){
         my $seq = $1;
         if($seq=~/A{7}/i || $seq=~/T{7}/i || $seq=~/C{7}/i || $seq=~/G{7}/i){
            $lcr++;
         }elsif(! defined $unique->{$seq}){
            $unique->{$seq}++;
            $ct++;
            print IN "$head\n$seq\n" if ($ct <= $entries);
            print SU "$head\n$seq\n" if ($ct <= $entries);

            if($ct >= $entries){
               $tot+=$ct;
               $ct = 0;
               $mod++;
               $modfa = $fa . "." . $mod;
               close IN;
               open (IN, ">$dir/$modfa");
            }
         }elsif(defined $unique->{$seq}){
            $dup++;
         }
      }
   }
   $unique={};
   $tot+=$ct;

   close OUT;
   close IN;
   close SU;

   print "Low complexity reads: $lcr\nExact duplicates: $dup\nTotal in split files: $tot\n";
   my @fof_ct=(1..$mod);
   my @file_input;
   foreach my $fc (@fof_ct){my $concat = $dir . "/" . $fa . "." . $fc;push @file_input, $concat;}

   return \@file_input;
}
