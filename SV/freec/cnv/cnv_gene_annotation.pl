#!/usr/bin/env perl
use strict;
use warnings;
use Cwd 'abs_path';
use File::Basename;
use Getopt::Long;
use Data::Dumper;
use FindBin qw($Bin);

# Global variable
my ($help, $outDir, $gene);

# Get Parameter
GetOptions(
	"h|help" => \$help,	
	"outDir=s" => \$outDir,
	"gene=s" => \$gene,
);

my $tmpDir = `pwd`;
chomp $tmpDir;
$outDir ||= "$tmpDir";
$gene ||= "$Bin/../db/hg19_refGene.bed";

# Guide for program
my $guide_separator = "#" x 80;
my $program = basename(abs_path($0));
$program =~ s/\.pl//;
my $guide=<<INFO;
VER
	AUTHOR: xuxiangyang(xy_xu\@foxmail.com)
	NAME: $program
	PATH: $0
        VERSION: v0.1	2017-10-16
NOTE

USAGE
	$program <options> cnv.file
	$guide_separator Basic $guide_separator
	--help			print help information
	--outDir <s>		script out Dir, default "$outDir"
	--gene <s>		gene bed file, default "$gene"

INFO

die $guide if (@ARGV == 0 || defined $help);

# Main
my (%region, %geneInfo);

open GN, $gene or die $!;
while (<GN>) {
	next if (/^#/);
	chomp;
	my @rows = split /\s+/;
	$rows[0] =~ s/chr//gi;
	$rows[0] = 23 if ($rows[0] =~ /X/i);
        $rows[0] = 24 if ($rows[0] =~ /Y/i);
	$region{$rows[0]}{$rows[1]} = $rows[2];
	$geneInfo{$rows[0]}{$rows[1]}{$rows[2]} = $rows[3];
}
close GN;

open VAR, $ARGV[0] or die $!;
while (<VAR>) {
	next if (/^#/);
	chomp;
	my @rows = split /\s+/;
	$rows[0] =~ s/chr//gi;
	$rows[0] = 23 if ($rows[0] =~ /X/i);
        $rows[0] = 24 if ($rows[0] =~ /Y/i);
	my $line = $_;
	if ($region{$rows[0]}) {
		my $geneList = "";
		foreach my $start (keys %{$region{$rows[0]}}) {
			if (&overlap($rows[1], $rows[2], $start, $region{$rows[0]}{$start})) {
				my $geneName = $geneInfo{$rows[0]}{$start}{$region{$rows[0]}{$start}};
				if ($geneList =~ /$geneName/) {
					next;
				} else {
					if ($geneList) {
						$geneList .= "," . $geneName;
					} else {
						$geneList = $geneName;	
					}
				}		
			}
		}
		if ($geneList eq "") {
			print "$line\t-\n";
		} else {
			print "$line\t$geneList\n";
		}
	} else {
		print "$line\t-\n";
	}	
}
close VAR;


sub overlap {
	my ($s, $e, $db_s, $db_e) = @_;
	my $len = $e - $s;
	my $db_len = $db_e - $db_s;
	my $intersect;
	# 位于目标区间左侧
	if ($e <= $db_s) {
		$intersect = 0;		
	# 与目标区间左侧相交
	} elsif ($e > $db_s && $e <= $db_e && $s <= $db_s) {
		$intersect = $e - $db_s;
	# 处于目标区间内 
	} elsif ($e > $db_s && $e <= $db_e && $s > $db_s) {
		$intersect = $len;
	# 与目标区间右侧相交
	} elsif ($e > $db_e && $s > $db_s && $s <= $db_e) {
		$intersect = $db_e - $s;
	# 位于目标区间右侧
	} elsif ($e > $db_e && $s > $db_e) {
		$intersect = 0;
	# 目标区间位于该区间内侧
	} elsif ($e >= $db_e && $s <= $db_s) {
		$intersect = $db_len;
	} 
	return $intersect;
}
