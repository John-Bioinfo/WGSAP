#!/usr/bin/env perl
use strict;
use warnings;
use Cwd 'abs_path';
use File::Basename;
use Getopt::Long;
use Data::Dumper;
use FindBin qw($Bin);

# Global variable
my ($help, $outDir, $window, $threads, $mateOrientation);

# Get Parameter
GetOptions(
	"h|help" => \$help,	
	"outDir=s" => \$outDir,
	"window=i" => \$window,
	"threads=i" => \$threads,
	"mateOrientation=s" => \$mateOrientation,
);

my $tmpDir = `pwd`;
chomp $tmpDir;
$outDir ||= "$tmpDir";
$window ||= 50000;
$threads ||= 14;

# Guide for program
my $guide_separator = "#" x 80;
my $program = basename(abs_path($0));
$program =~ s/\.pl//;
my $guide=<<INFO;
VER
	AUTHOR: xuxiangyang(xy_xu\@foxmail.com)
	NAME: $program
	PATH: $0
        VERSION: v0.1	2018-02-08
NOTE

USAGE
	$program <options> *.bam 
	$guide_separator Basic $guide_separator
	--help			print help information
	--outDir <s>		script out Dir, default "$outDir"
	--window <i>		sliding window for count reads, default $window
	--threads <i>		threads for program parallel, default $threads
	--mateOrientation <s>   format of reads (in mateFile),0 (for single ends), RF (Illumina mate-pairs), FR (Illumina paired-ends), FF (SOLiD mate-pairs)

INFO

die $guide if (@ARGV == 0 || defined $help);
die "Please set parameter --mateOrientation!!\n" unless (defined $mateOrientation);

# Main
my $path = abs_path($ARGV[0]);
my $file = basename $path;
my $prefix = $file;
$prefix =~ s/.dup.bam//i;

my $config=<<CONFIG;
[general]
chrLenFile = /datapool/home/xuxiangyang/pipeline/exome/SV/freec/db/hg19.len
ploidy = 2
breakPointThreshold = 1
window = $window
chrFiles = /datapool/home/xuxiangyang/pipeline/exome/db/bwa/hg19_fa_split/
maxThreads = $threads
outputDir = $outDir 
sambamba = /datapool/home/xuxiangyang/pipeline/exome/SV/freec/bin/sambamba_v0.6.6
SambambaThreads = $threads
minMappabilityPerWindow = 0.85
gemMappabilityFile = /datapool/home/xuxiangyang/pipeline/exome/SV/freec/db/out100m2_hg19.gem
breakPointType = 4
uniqueMatch=TRUE
#sex

[sample]
mateFile = $path 
inputFormat = BAM
mateOrientation = $mateOrientation
CONFIG


open CFG, ">$outDir/config_WGS.txt" or die $!;
print CFG $config;
close CFG;

open SHELL, ">$outDir/$prefix.cnv.sh" or die $!;
print SHELL "/datapool/home/xuxiangyang/pipeline/exome/SV/freec/bin/freec -conf $outDir/config_WGS.txt\n";
print SHELL "sex=`awk '{if(\$1==22) {normal+=\$3}; if(\$1==\"Y\") {sex+=\$3};} END {if(sex/normal>0.2) print \"XY\"; else print \"XX\"}' $outDir/${file}_sample.cpn`\n";
print SHELL "sed \"s/#sex/sex=\$sex/\" $outDir/config_WGS.txt > $outDir/config_WGS_sex.txt\n";
print SHELL "/datapool/home/xuxiangyang/pipeline/exome/SV/freec/bin/freec -conf $outDir/config_WGS_sex.txt\n";
print SHELL "cat /datapool/home/xuxiangyang/pipeline/exome/SV/freec/bin/scripts/makeGraph.R | /datapool/bin/R --slave --args 2 $outDir/${file}_ratio.txt\n";
print SHELL "awk '{print \$0\"\\t\"\$3-\$2}' $outDir/${file}_CNVs > $outDir/${file}_CNVs.size\n";
print SHELL "perl /datapool/home/xuxiangyang/pipeline/exome/SV/freec/cnv/cnv_N_ratio.pl $outDir/${file}_CNVs.size > $outDir/${file}_CNVs.size.N\n";
print SHELL "awk '{if(\$6 >= 100000 && \$7 < 0.25) print}' $outDir/${file}_CNVs.size.N > $outDir/${file}_CNVs.size.N.filter\n";
print SHELL "db=`ls -th /datapool/home/xuxiangyang/pipeline/exome/SV/freec/cnv/cnv.*.db | head -1`\n";
print SHELL "perl /datapool/home/xuxiangyang/pipeline/exome/SV/freec/cnv/cnv_freq_annotation.pl --cnvDB \$db $outDir/${file}_CNVs.size.N > $outDir/${file}_CNVs.size.N.freq\n";
print SHELL "perl /datapool/home/xuxiangyang/pipeline/exome/SV/freec/cnv/cnv_gene_annotation.pl $outDir/${file}_CNVs.size.N.freq > $outDir/${file}_CNVs.size.N.freq.gene\n";
print SHELL "awk '{if(\$6 >= 100000 && \$7 < 0.25 && \$8 < 2 && \$10 != \"-\" && \$4 < 5) print }' $outDir/${file}_CNVs.size.N.freq.gene > $outDir/${file}_CNVs.size.N.freq.gene.filter\n";
close SHELL;

system("Add_time_for_script.sh $outDir/$prefix.cnv.sh") == 0 or die $!;
