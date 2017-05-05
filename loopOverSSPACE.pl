#!/usr/bin/perl

use strict;
use 5.010;
use Getopt::Long qw(GetOptions);
Getopt::Long::Configure qw(gnu_getopt);
use Data::Dumper;
use Pod::Usage;
use File::Copy;
use Cwd;

#Author: Jitendra Narayan
#Usage: perl loopOverSSPACE.pl <config_file> <outfile> <cfile> <thread> <loop>

my ($ifile, $ofile, $config, $thread, $debug, $help, $man, $loop);
my $version=0.1;
GetOptions(
    'ifile|i=s' 	=> \$ifile,	# Contig file name
    'ofile|o=s' 	=> \$ofile,	# OutFolder name
    'cfile|c=s' 	=> \$config,	# Config file for all SSPACE parameters
    'speedup|s=i' 	=> \$thread, 	# This not useful here .. as you can set it in config file !! Currently not used
    'loop|l=i' 		=> \$loop,	# How many round of scaffolder to run
    'help|h' 		=> \$help
) or die &help($version);
&help($version) if $help;

my $dir = getcwd;

#pod2usage("$0: \nI am afraid, no files given.")  if ((@ARGV == 0) && (-t STDIN));

if (!$ifile or !$ofile or !$config) { help($version) }
if (!$thread) { $thread = `grep -c -P '^processor\\s+:' /proc/cpuinfo` }
my $parameters = readConfig ($config); 
my $param = join (' ', @$parameters); $param =~ s/=/ /g;

print "$param\n";
print "$dir\n";

print "\nWorking on $loop round for scaffoldings \n_______\n\n";

for (my $aa=0; $aa<=$loop; $aa++) {
  print "Working on loop number $aa scaffoldings\n";
  runSSPACE($ifile, $aa);
  print "DONE ... round $aa!\n";
  #system ( "cp -rf $loop$ofile/scaffolds.fasta $ifile");
  unlink "$dir/$ifile";
  my $outdirname="$ofile"."$aa";
print "$outdirname/scaffolds.fasta,$ifile\n";
  copy("$outdirname/scaffolds.fasta","$ifile") or die "The move operation failed: $!"; ## Need to check for other location

}

sub runSSPACE {
my ($ifile, $loop)=@_;
   my $mySSPACE="perl SSPACE-LongRead.pl $param -c $ifile -b $ofile$loop";
   system ("$mySSPACE");

}

#Read config files
sub readConfig {
my ($file) = @_;
my $fh= read_fh($file);
my @lines;
while (<$fh>) {
    chomp;
    next if /^#/;
    next if /^$/;
    $_ =~ s/^\s+|\s+$//g;
    push @lines, $_;
}
close $fh or die "Cannot close $file: $!";
return \@lines;
}

#Open and Read a file
sub read_fh {
    my $filename = shift @_;
    my $filehandle;
    if ($filename =~ /gz$/) {
        open $filehandle, "gunzip -dc $filename |" or die $!;
    }
    else {
        open $filehandle, "<$filename" or die $!;
    }
    return $filehandle;
}

#Help section
sub help {
  my $ver = $_[0];
  print "\n loopOverSSPACE $ver\n\n";

  print "Usage: $0 --ifile <> --ofile <> --cfile <> --speedup --loop <#> \n\n";
  print	"Options:\n";
  print "	--ifile|-i	query multifasta/fasta file\n";
  print "	--ofile|-o	target outfolder\n";
  print "	--cfile|-c	config file\n";
  print "	--speedup|-s	number of core to use\n";
  print "	--loop|-l	round for scaffolder to run\n";
  print "     	--help|-h	brief help message\n";

exit;
}

