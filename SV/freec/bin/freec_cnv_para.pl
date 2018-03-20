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
$mateOrientation ||= "RF";

# Guide for program
my $guide_separator = "#" x 80;
my $program = basename(abs_path($0));
$program =~ s/\.pl//;
my $guide=<<INFO;
VER
	AUTHOR: xuxiangyang(xy_xu\@foxmail.com)
	NAME: $program
	PATH: $0
        VERSION: v0.1	2017-10-09
NOTE
	bam.lst format:
	/path/for/bam	[XY]

USAGE
	$program <options> bam.lst 
	$guide_separator Basic $guide_separator
	--help			print help information
	--outDir <s>		script out Dir, default "$outDir"
	--window <i>		sliding window for count reads, default $window
	--threads <i>		threads for program parallel, default $threads
	--mateOrientation <s>	format of reads (in mateFile),0 (for single ends), RF (Illumina mate-pairs), FR (Illumina paired-ends), FF (SOLiD mate-pairs), default "$mateOrientation"

INFO

die $guide if (@ARGV == 0 || defined $help);

# Main
system("mkdir -p $outDir/CNV") == 0 or die $!;
open SLS, ">$outDir/CNV/shell.lst" or die $!;
open LST, $ARGV[0] or die $!;
while (<LST>) {
	next if(/^#/);
	chomp;
	my @arr = split /\s+/;
	my $path = $arr[0];
	my $file = basename $path;
	my $prefix = $file;
	$prefix =~ s/.sort.bam//i;
	$prefix =~ s/.bam//i;
	system("mkdir -p $outDir/CNV/$prefix") == 0 or die $!;
my $config=<<CONFIG;
[general]
chrLenFile = /datapool/home/xuxiangyang/pipeline/exome/SV/freec/db/hg19.len
ploidy = 2
breakPointThreshold = 1
window = $window
chrFiles = /datapool/home/xuxiangyang/pipeline/exome/db/bwa/hg19_fa_split/
maxThreads = $threads
outputDir = $outDir/CNV/$prefix 
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
	open CFG, ">$outDir/CNV/$prefix/config_WGS.txt" or die $!;
	print CFG $config;
	close CFG;
	open SHELL, ">$outDir/CNV/$prefix/$prefix.cnv.sh" or die $!;
	print SHELL "/datapool/home/xuxiangyang/pipeline/exome/SV/freec/bin/freec -conf $outDir/CNV/$prefix/config_WGS.txt\n";
	print SHELL "sex=`awk '{if(\$1==22) {normal+=\$3}; if(\$1==\"Y\") {sex+=\$3};} END {if(sex/normal>0.2) print \"XY\"; else print \"XX\"}' $outDir/CNV/$prefix/${file}_sample.cpn`\n";
	print SHELL "sed \"s/#sex/sex=\$sex/\" $outDir/CNV/$prefix/config_WGS.txt > $outDir/CNV/$prefix/config_WGS_sex.txt\n";
	print SHELL "/datapool/home/xuxiangyang/pipeline/exome/SV/freec/bin/freec -conf $outDir/CNV/$prefix/config_WGS_sex.txt\n";
	print SHELL "cat /datapool/home/xuxiangyang/pipeline/exome/SV/freec/bin/scripts/makeGraph.R | /datapool/bin/R --slave --args 2 $outDir/CNV/$prefix/${file}_ratio.txt\n";
	print SHELL "awk '{print \$0\"\\t\"\$3-\$2}' $outDir/CNV/$prefix/${file}_CNVs > $outDir/CNV/$prefix/${file}_CNVs.size\n";
	print SHELL "perl /datapool/home/xuxiangyang/pipeline/exome/SV/freec/cnv/cnv_N_ratio.pl $outDir/CNV/$prefix/${file}_CNVs.size > $outDir/CNV/$prefix/${file}_CNVs.size.N\n";
	print SHELL "awk '{if(\$6 >= 100000 && \$7 < 0.25) print}' $outDir/CNV/$prefix/${file}_CNVs.size.N > $outDir/CNV/$prefix/${file}_CNVs.size.N.filter\n";
	print SHELL "db=`ls -th /datapool/home/xuxiangyang/pipeline/exome/SV/freec/cnv/cnv.*.db | head -1`\n";
	print SHELL "perl /datapool/home/xuxiangyang/pipeline/exome/SV/freec/cnv/cnv_freq_annotation.pl --cnvDB \$db $outDir/CNV/$prefix/${file}_CNVs.size.N > $outDir/CNV/$prefix/${file}_CNVs.size.N.freq\n";
	print SHELL "perl /datapool/home/xuxiangyang/pipeline/exome/SV/freec/cnv/cnv_gene_annotation.pl $outDir/CNV/$prefix/${file}_CNVs.size.N.freq > $outDir/CNV/$prefix/${file}_CNVs.size.N.freq.gene\n";
	print SHELL "awk '{if(\$6 >= 100000 && \$7 < 0.25 && \$8 < 2 && \$10 != \"-\" && \$4 < 5) print }' $outDir/CNV/$prefix/${file}_CNVs.size.N.freq.gene > $outDir/CNV/$prefix/${file}_CNVs.size.N.freq.gene.filter\n";
	close SHELL;
	system("Add_time_for_script.sh $outDir/CNV/$prefix/$prefix.cnv.sh") == 0 or die $!;
	print SLS "$outDir/CNV/$prefix/$prefix.cnv.sh\n";
}
open RUN, ">$outDir/CNV/run.sh" or die $!;
print RUN "cat $outDir/CNV/shell.lst | while read i; do qsub -l nodes=1:ppn=$threads -o \$i.o -e \$i.e \$i; done\n";
close RUN;
close LST;
close SLS;
