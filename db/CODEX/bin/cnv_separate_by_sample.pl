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
        VERSION: v0.1	2016-12-08
NOTE

USAGE
	$program <options> sample.list all.cnv.txt
	$guide_separator Basic $guide_separator
	--help			print help information
	--outDir <s>		script out Dir, default "$outDir"

INFO
# Call guide
die $guide if (@ARGV == 0 || defined $help);

# Program check

# Main
open IF, $ARGV[0] or die $!;
while (<IF>) {
	next if (/^#/);
	chomp;
	system("grep -w $_  $ARGV[1] > $outDir/$_.cnv.tmp") == 0 or die $!;
	system("awk 'BEGIN {OFS = \"\t\"} {print \$2, \$4, \$5, 0, 0, \$6, \$11, \$12, \$13}' $outDir/$_.cnv.tmp > $outDir/$_.cnv.tmp2") == 0 or die $!;	
	system("sort -k 1.4,1n -k 2,2n $outDir/$_.cnv.tmp2 > $outDir/$_.cnv.annovar") == 0 or die $!;
	system("rm $outDir/$_.cnv.tmp*") == 0 or die $!;
}
close IF;
