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
        VERSION: v0.1	2016-11-25
NOTE
	1. bam file shoud be absolute path

USAGE
	$program <options> bam.list
	$guide_separator Basic $guide_separator
	--help			print help information
	--outDir <s>		script out Dir, default "$outDir"

INFO
# Call guide
die $guide if (@ARGV == 0 || defined $help);

# Program check
# Create Directory
my $chrDir = "$outDir/chr";
system("mkdir -p $chrDir") == 0 or die $!;
my $shell = "$outDir/split_shell";
system("mkdir -p $shell") == 0 or die $!;
foreach my $name (1..22, 'X', 'Y') {
	system("mkdir -p $chrDir/chr$name") == 0 or die $!;
}

# Main
my $bamList = shift;

system("awk -F \"\/\" '{print \$NF}' $bamList | awk -F \".\" '{print \$1}' > $outDir/sampname") == 0 or die $!;

open BL, $bamList or die $!;
while (<BL>) {
	next if(/^#/);
	unless (/bam$/) {
		print "$_ may be not bam file!\tIt will be ignored!\n";	
		next;
	}
	chomp;
	my $bamPath = abs_path($_);
	my $bamFile = basename(abs_path($_));
	my $SampleId = $bamFile;
	$SampleId =~ s/([^\.]+).*/$1/;
	open OUTPUT, ">$shell/$SampleId.bam.split.lst" or die $!;
	system("mkdir -p $shell/$SampleId")  == 0 or die $!;
	foreach my $name (1..22, 'X', 'Y') {
		open S, ">$shell/$SampleId/$SampleId.bam.split.chr$name.sh" or die $!;
		print S "/HOME/cheerland_1/bin/samtools view -b -@ 1 -o $chrDir/chr$name/$SampleId.chr$name.bam $bamPath chr$name\n";	
		print S "/HOME/cheerland_1/bin/samtools index $chrDir/chr$name/$SampleId.chr$name.bam\n";
		close S;
		print OUTPUT "$shell/$SampleId/$SampleId.bam.split.chr$name.sh\n";
	}
	close OUTPUT;
}
close BL;
