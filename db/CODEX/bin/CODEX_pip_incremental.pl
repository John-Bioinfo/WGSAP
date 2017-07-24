#!/usr/bin/env perl
use strict;
use warnings;
use Cwd 'abs_path';
use File::Basename;
use Getopt::Long;
use Data::Dumper;

# Global variable
my ($help, $outDir, $codexDB);

# Get Parameter
GetOptions(
	"h|help" => \$help,	
	"outDir=s" => \$outDir,
	"codexDB=s" => \$codexDB,
);

my $tmpDir = `pwd`;
chomp $tmpDir;
$outDir ||= "$tmpDir";
$codexDB ||= "/HOME/cheerland_1/WORKSPACE/pipeline/exome/db/CODEX/incremental/depthDB";

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

USAGE
	$program <options> iputDir
	$guide_separator Basic $guide_separator
	--help			print help information
	--outDir <s>		script out Dir, default "$outDir"
	--codexDB <s>		dir for codex DataBase, default "$codexDB"

INFO
# Call guide
die $guide if (@ARGV == 0 || defined $help);

# DataBase intelligent retrieval
$codexDB .= "/" . `ls $codexDB -t | head -1`;
chomp $codexDB;

# Create Directory
system("mkdir -p $outDir/output") == 0 or die $!;

# Main
my $inputDir = shift;

open OUTPUT, ">$outDir/CODEX.incremental.lst" or die $!;
my $shellDir = "$outDir/codex_shell";
system("mkdir -p $shellDir")  == 0 or die $!;
foreach my $name (1..22, 'X', 'Y') {
	open S, ">$shellDir/CODEX.incremental.chr$name.sh" or die $!;
	print S "Rscript /HOME/cheerland_1/WORKSPACE/pipeline/exome/db/CODEX/bin/CODEX_incremental_chr.R chr$name $inputDir/chr $outDir/output codex 9 $codexDB\n";
	close S;
	system ("Add_time_for_script.sh $shellDir/CODEX.incremental.chr$name.sh") == 0 or die $!;
	print OUTPUT "$shellDir/CODEX.incremental.chr$name.sh\n";
}
close OUTPUT;
