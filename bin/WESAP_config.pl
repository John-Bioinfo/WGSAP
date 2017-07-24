#!/HOME/cheerland_1/WORKSPACE/soft/install/bin/perl
use strict;
use warnings;
use Cwd 'abs_path';
use File::Basename;
use Getopt::Long;
use Data::Dumper;

# Global variable
my ($help, $outDir);

# Get Parameter
GetOptions(
	"h|help" => \$help,	
	"outDir=s" => \$outDir,
);

my $tmpDir = `pwd`;
chomp $tmpDir;
$outDir ||= "$tmpDir";

# Guide for program
my $guide_separator = "#" x 80;
my $program = basename(abs_path($0));
$program =~ s/\.pl//;
my $guide=<<INFO;
VER
	AUTHOR: xuxiangyang(xy_xu\@foxmail.com)
	NAME: $program
	PATH: $0
        VERSION: v0.1	2016-12-06
NOTE
	fq1.list file should be absolute path
USAGE
	$program <options> fq1.list
	$guide_separator Basic $guide_separator
	--help			print help information
	--outDir <s>		script out Dir, default "$outDir"

INFO
# Call guide
die $guide if (@ARGV == 0 || defined $help);

# Program check

# Main

open IN, $ARGV[0] or die;
while (<IN>) {
	next if (/^#/);
	chomp;
	my $fq1 = $_;
	my $fq2 = $fq1;
	$fq2 =~ s/1.clean.fq.gz/2.clean.fq.gz/;
	my $file = basename $fq1;
	my @arr = split "_", $file;
	print "$fq1\t$fq2\t$arr[0]\t$arr[1]\t$arr[2]\n";
}
close IN;
