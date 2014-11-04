=head1 NAME

utility.pm - library modules that contains generic utilities

=head1 SYNOPSIS

use utility qw(:all);

=head2 NOTE

currently located in '~/utilities'

=head2 RECENT CHANGES

None.  Last modified 21 December 2006

=head1 DESCRIPTION

Generic utility

=head1 EXAMPLES

use lib './';

use utilities::utility qw(:all);

=head1 SEE ALSO

None

=head1 BUGS

Contact author via email

=head1 AUTHOR

Written by Malachi Griffith (malachig@bcgsc.ca)

=head1 ACKNOWLEDGEMENTS

University of British Columbia Graduate Studies

Michael Smith Foundation for Health Research

Natural Sciences and Engineering Research Council

Genome British Columbia

=head1 AFFLIATIONS

Malachi Griffith is supervised by Marco A. Marra

Genome Sciences Centre, BC Cancer Research Centre, BC Cancer Agency, UBC Faculty of Medicine - Medical Genetics

=head1 SUBROUTINES

=cut

package utilities::utility;
require Exporter;

@ISA = qw( Exporter );
@EXPORT = qw();

@EXPORT_OK = qw(&checkMaxPacketSize &connectDB &loadEnsemblApi &createNewDir &checkDir);

%EXPORT_TAGS = (
     all => [qw(&checkMaxPacketSize &connectDB &loadEnsemblApi &createNewDir &checkDir )]
);

use strict;
use Data::Dumper;
use DBI;
use Term::ANSIColor qw(:constants);


=head2 checkMaxPacketSize()

=over 3

=item Function:

Check the database max_allowed_packet variable to ensure that large gene entries will work

=item Return:

N/A - Will exit if packet size is not sufficient

=item Args:

'-dbh' => database handle

=item Example(s):

&checkMaxPacketSize('-dbh'=>$alexa_dbh);

=back

=cut

#############################################################################################
#checkMaxPacketSize                                                                         #
#############################################################################################
sub checkMaxPacketSize{
  my %args = @_;
  my $dbh = $args{'-dbh'};

  my $sql = "SHOW GLOBAL variables LIKE 'max_allowed_packet'";
  my $sth = $dbh->prepare("$sql");
  $sth->execute();
  my $packet_size = $sth->fetchrow_array();
  unless ($packet_size > 5000000){
    print RED, "\nmax_allowed_packet = $packet_size bytes", RESET;
    print RED, "\nWARNING: max_allowed_packet variable is too small to allow insertion of large genes", RESET;
    print RED, "\nGet a DB Admin to execute the following: SET GLOBAL max_allowed_packet=10000000\n\n", RESET;
    exit();
  }

  print BLUE, "\nFound a suitable packet size ($packet_size) for the target ALEXA database\n\n", RESET;
  $sth->finish();
  return();
}


=head2 connectDB

=over 3

=item Function:

Get database connection handler

=item Return:

database handle

=item Args:

'-database' - mysql database name

'-server' - mysql host

'-user' - mysql user name

'-password' - mysql password

=item Example(s):

$dbh = &connectDB('-database'=>'database_name', '-server'=>'server_name', '-user'=>'user_name', '-password'=>'passwd')

=back

=cut

###############################################################################################################
#Create mysql database connection                                                                             #
###############################################################################################################
sub connectDB {
  my %args = @_;
  my $database_name = $args{'-database'};
  my $database_host = $args{'-server'};
  my $user_name = $args{'-user'};
  my $user_pw = $args{'-password'};

  my $dbh = DBI->connect( "dbi:mysql:database=$database_name;host=$database_host", $user_name, $user_pw, { PrintError => 1 } );
  return $dbh;
}


=head2 loadEnsemblApi

=over 3

=item Function:

Load API code for specified EnsEBML veriosn

=item Return:

NULL

=item Args:

'-api' - EnsEMBL API version.  e.g. '49'

=item Example(s):

loadEnsemblApi('-api'=>$ensembl_api_version)

=back

=cut


##############################################################################################################
#Load EnsEMBL API library code                                                                               #
##############################################################################################################
sub loadEnsemblApi{
  my %args = @_;
  my $ensembl_api_version = $args{'-api'};

  #**********************************************************************************************************
  #IMPORTANT NOTE: You must have the correct Ensembl API installed locally AND bioperl 1.2 or greater!!
  #Both the EnsEMBL core API as well as Compara are required
  #Refer to the ALEXA manual for additional details on how to install these
  #Then update the following paths:
  if ($ensembl_api_version <= 33){
    print RED, "\nEnsEMBL API version earlier than v34 do not work with the connection types used in this script!\n\n", RESET;
    exit();
  }
  if ($ensembl_api_version =~ /^\d+/){
    if ($ensembl_api_version eq "34"){
      unshift(@INC, "/home/malachig/perl/ensembl_34_perl_API/ensembl/modules");
      unshift(@INC, "/home/malachig/perl/ensembl_34_perl_API/ensembl-variation/modules");
    }elsif ($ensembl_api_version eq "35"){
      unshift(@INC, "/home/malachig/perl/ensembl_35_perl_API/ensembl/modules");
      unshift(@INC, "/home/malachig/perl/ensembl_35_perl_API/ensembl-variation/modules");
    }elsif ($ensembl_api_version eq "36"){
      unshift(@INC, "/home/malachig/perl/ensembl_36_perl_API/ensembl/modules");
      unshift(@INC, "/home/malachig/perl/ensembl_36_perl_API/ensembl-variation/modules");
    }elsif ($ensembl_api_version eq "37"){
      unshift(@INC, "/home/malachig/perl/ensembl_37_perl_API/ensembl/modules");
      unshift(@INC, "/home/malachig/perl/ensembl_37_perl_API/ensembl-variation/modules");
    }elsif ($ensembl_api_version eq "38"){
      unshift(@INC, "/home/malachig/perl/ensembl_38_perl_API/ensembl/modules");
      unshift(@INC, "/home/malachig/perl/ensembl_38_perl_API/ensembl-variation/modules");
    }elsif ($ensembl_api_version eq "39"){
      unshift(@INC, "/home/malachig/perl/ensembl_39_perl_API/ensembl/modules");
      unshift(@INC, "/home/malachig/perl/ensembl_39_perl_API/ensembl-variation/modules");
    }elsif ($ensembl_api_version eq "40"){
      unshift(@INC, "/home/malachig/perl/ensembl_40_perl_API/ensembl/modules");
      unshift(@INC, "/home/malachig/perl/ensembl_40_perl_API/ensembl-variation/modules");
    }elsif ($ensembl_api_version eq "41"){
      unshift(@INC, "/home/malachig/perl/ensembl_41_perl_API/ensembl/modules");
      unshift(@INC, "/home/malachig/perl/ensembl_41_perl_API/ensembl-variation/modules");
    }elsif($ensembl_api_version eq "42"){
      unshift(@INC, "/home/malachig/perl/ensembl_42_perl_API/ensembl/modules");
      unshift(@INC, "/home/malachig/perl/ensembl_42_perl_API/ensembl-variation/modules");
    }elsif($ensembl_api_version eq "43"){
      unshift(@INC, "/home/malachig/perl/ensembl_43_perl_API/ensembl/modules");
      unshift(@INC, "/home/malachig/perl/ensembl_43_perl_API/ensembl-variation/modules");
    }elsif($ensembl_api_version eq "44"){
      unshift(@INC, "/home/malachig/perl/ensembl_44_perl_API/ensembl/modules");
      unshift(@INC, "/home/malachig/perl/ensembl_44_perl_API/ensembl-variation/modules");
    }elsif($ensembl_api_version eq "45"){
      unshift(@INC, "/home/malachig/perl/ensembl_45_perl_API/ensembl/modules");
      unshift(@INC, "/home/malachig/perl/ensembl_45_perl_API/ensembl-variation/modules");
    }elsif($ensembl_api_version eq "46"){
      unshift(@INC, "/home/malachig/perl/ensembl_46_perl_API/ensembl/modules");
      unshift(@INC, "/home/malachig/perl/ensembl_46_perl_API/ensembl-variation/modules");
    }elsif($ensembl_api_version eq "47"){
      unshift(@INC, "/home/malachig/perl/ensembl_47_perl_API/ensembl/modules");
      unshift(@INC, "/home/malachig/perl/ensembl_47_perl_API/ensembl-variation/modules");
    }elsif($ensembl_api_version eq "48"){
      unshift(@INC, "/home/malachig/perl/ensembl_48_perl_API/ensembl/modules");
      unshift(@INC, "/home/malachig/perl/ensembl_48_perl_API/ensembl-variation/modules");
    }elsif($ensembl_api_version eq "49"){
      unshift(@INC, "/home/malachig/perl/ensembl_49_perl_API/ensembl/modules");
      unshift(@INC, "/home/malachig/perl/ensembl_49_perl_API/ensembl-variation/modules");
    }elsif($ensembl_api_version eq "50"){
      unshift(@INC, "/home/malachig/perl/ensembl_50_perl_API/ensembl/modules");
      unshift(@INC, "/home/malachig/perl/ensembl_50_perl_API/ensembl-variation/modules");
    }elsif($ensembl_api_version eq "51"){
      unshift(@INC, "/home/malachig/perl/ensembl_51_perl_API/ensembl/modules");
      unshift(@INC, "/home/malachig/perl/ensembl_51_perl_API/ensembl-variation/modules");
    }else{
      print RED, "\nEnsEMBL API version: $ensembl_api_version is not defined, modify script before proceeding\n\n", RESET;
      exit();
    }
  }else{
    print RED, "\nEnsEMBL API version format: $ensembl_api_version not understood!\n\n", RESET;
    exit();
  }

  use lib "/home/malachig/perl/bioperl-1.4";    #Bioperl
  require Bio::EnsEMBL::DBSQL::DBAdaptor; #Used for local connections to EnsEMBL core databases
  require Bio::EnsEMBL::Variation::DBSQL::DBAdaptor; #Used for local connections to EnsEMBL variation databases

  return();
}



=head2 createNewDir

=over 3

=item Function:

Create a new directory cleanly in the specified location - Prompt user for confirmation

=item Return:

Full path to new directory

=item Args:

'-path' - Full path to new directoy

'-new_dir_name' - Name of new directory

=item Example(s):

my $fasta_dir = &createNewDir('-path'=>$temp_dir, '-new_dir_name'=>"ensembl_genes_fasta");

=back

=cut

###############################################################################################################
#Create a new directory in a specified location                                                               #
###############################################################################################################
sub createNewDir{
  my %args = @_;
  my $base_path = $args{'-path'};
  my $name = $args{'-new_dir_name'};
  my $force = $args{'-force'};

  #Now make sure the desired new dir does not already exist
  unless ($base_path =~ /.*\/$/){
    $base_path = "$base_path"."/";
  }

  #First make sure the specified base path exists and is a directory
  unless (-e $base_path && -d $base_path){
    print RED, "\nSpecified working directory: $base_path does not appear valid! Create a working directory before proceeding\n\n", RESET;
    exit();
  }

  unless ($name =~ /.*\/$/){
    $name = "$name"."/";
  }

  my $new_path = "$base_path"."$name";

  if (-e $new_path && -d $new_path){

    if ($force){
      #If this directory already exists, and the -force option was provide, delete this directory and start it cleanly
      if ($force eq "yes"){
	print YELLOW, "\nForcing clean creation of $new_path\n\n", RESET;
	my $command = "rm -r $new_path";
	system ($command);
	mkdir($new_path);
      }else{
	print RED, "\nThe '-force' option provided to utility.pm was not understood!!", RESET;
	exit();
      }

    }else{

      #If this directory already exists, ask the user if they wish to erase it and start clean
      print YELLOW, "\nNew dir: $new_path already exists.\n\tDo you wish to delete it and create it cleanly (y/n)? ", RESET;
      my $answer = <>;

      chomp($answer);

      if ($answer =~ /^y$/i | $answer =~ /^yes$/i){
	my $command = "rm -r $new_path";
	system ($command);
	mkdir($new_path);
      }else{
	print YELLOW, "\nUsing existing directory, some files may be over-written and others that are unrelated to the current analysis may remain!\n", RESET;
      }
    }

  }else{
    mkdir($new_path)
  }
  return($new_path);
}


=head2 checkDir

=over 3

=item Function:

Check validity of a directory and empty if the user desires - Prompt user for confirmation

=item Return:

Path to clean,valid directory

=item Args:

'-dir' - Full path to directory to be checked

'-clear' - 'yes/no' option to clear the specified directory of files

'-force' - 'yes/no' force clear without user prompt

=item Example(s):

my $working_dir = &checkDir('-dir'=>$working_dir, '-clear'=>"yes");

=back

=cut


#############################################################################################################################
#Check dir
#############################################################################################################################
sub checkDir{
  my %args = @_;
  my $dir = $args{'-dir'};
  my $clear = $args{'-clear'};
  my $force = $args{'-force'};

  unless ($dir =~ /\/$/){
    $dir = "$dir"."/";
  }
  unless (-e $dir && -d $dir){
    print RED, "\nDirectory: $dir does not appear to be valid!\n\n", RESET;
    exit();
  }

  unless ($force){
    $force = "no";
  }
  unless ($clear){
    $clear = "no";
  }

  #Clean up the working directory
  opendir(DIRHANDLE, "$dir") || die "\nCannot open directory: $dir\n\n";
  my @temp = readdir(DIRHANDLE);
  closedir(DIRHANDLE);

  if ($clear =~ /y|yes/i){

    if ($force =~ /y|yes/i){
      my $files_present = scalar(@temp) - 2;
      my $clean_dir_cmd = "rm -f $dir"."*";

    }else{

      my $files_present = scalar(@temp) - 2;
      my $clean_dir_cmd = "rm -f $dir"."*";

      unless ($files_present == 0){
	print YELLOW, "\nFound $files_present files in the specified directory ($dir)\nThis directory will be cleaned with the command:\n\t$clean_dir_cmd\n\nProceed (y/n)? ", RESET;

	my $answer = <>;
	chomp($answer);
	if ($answer =~ /y|yes/i){
	  system($clean_dir_cmd);
	}else{
	  print YELLOW, "\nContinuing and leaving files in place then ...\n\n", RESET;
	}
      }
    }
  }
  return($dir);
}



1;




