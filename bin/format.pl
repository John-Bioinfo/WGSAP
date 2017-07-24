#!/usr/bin/env perl
use strict;
use warnings;
use Cwd 'abs_path';
use File::Basename;
use Getopt::Long;
use Data::Dumper;

# Global variable
my ($help, $outDir, $siteDB);

# Get Parameter
GetOptions(
	"h|help" => \$help,	
	"outDir=s" => \$outDir,
	"siteDB=s" => \$siteDB,
);

my $tmpDir = `pwd`;
chomp $tmpDir;
$outDir ||= "$tmpDir";
$siteDB ||= "/WORK/cheerland_1/YCC/project/02_fude/anno.index";

# Guide for program
my $guide_separator = "#" x 80;
my $program = basename(abs_path($0));
$program =~ s/\.pl//;
my $guide=<<INFO;
VER
	AUTHOR: xuxiangyang(xy_xu\@foxmail.com)
	NAME: $program
	PATH: $0
        VERSION: v0.1	2016-10-24
NOTE

USAGE
	$program <options> sample.lst site.lst
	$guide_separator Basic $guide_separator
	--help			print help information
	--outDir <s>		script out Dir, default "$outDir"
	--siteDB <s>		site Data Base, default "$siteDB"

INFO

die $guide if (@ARGV == 0 || defined $help);

# Main

my ($sample_file, $site_file) = @ARGV;

my %sample;
open SP, $sample_file or die $!;
while (<SP>) {
	next if(/^#/);
	chomp;
	my @arr = split /\s+/;
	my $key = "$arr[0]_$arr[1]";
	$sample{$key} = $arr[2];
}
close SP;

my %db;
open DB, $siteDB or die $!;
while (<DB>) {
	next if(/^#/);
        chomp;
	my @arr = split /\s+/;
	$db{$arr[4]} = "$arr[1]\t$arr[2]\t$arr[3]";
}
close DB;

my %sample_infor;
my %column;
open ST, $site_file or die $!;
while (<ST>) {
	next if(/^#/);
	chomp;
	if (/R\d+C\d+/) {
		my @arr = split /\s+/;
		my $i = -1;
		foreach my $ele (@arr) {
			$i++;
			next if ($i == 0);
			$column{$i} = $sample{$ele};
		}
	}
	next unless(/\|/);
	my @arr2 = split /\s+/;
	my $j = -1;
	foreach my $genotype (@arr2) {
		$j++;
		next if ($j == 0);
		my @arr3 = split /\|/, $genotype;
		push @{$sample_infor{$column{$j}}}, "$arr2[0]&$arr3[0]";
	}
}
close ST;

foreach my $key (keys %sample_infor) {
	open OUT, ">$outDir/$key.txt" or die $!;
	foreach my $ele (@{$sample_infor{$key}}) {
		my @arr = split /\&/, $ele;
		if ($db{$arr[0]}) {
			print OUT "$db{$arr[0]}\t$arr[1]\n";
		} else {
			print "$key\t$ele\t$arr[0]\t$arr[1]\n";
		}
	}
	close OUT;
}
