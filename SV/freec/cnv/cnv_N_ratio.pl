#!/usr/bin/env perl
use strict;
use warnings;
use Cwd 'abs_path';
use File::Basename;
use Getopt::Long;
use Data::Dumper;
use FindBin qw($Bin);

# Global variable
my ($help, $outDir, $N_bed);

# Get Parameter
GetOptions(
	"h|help" => \$help,	
	"outDir=s" => \$outDir,
	"N_bed=s" => \$N_bed,
);

my $tmpDir = `pwd`;
chomp $tmpDir;
$outDir ||= "$tmpDir";
$N_bed ||= "$Bin/../db/hg19.N.bed";

# Guide for program
my $guide_separator = "#" x 80;
my $program = basename(abs_path($0));
$program =~ s/\.pl//;
my $guide=<<INFO;
VER
	AUTHOR: xuxiangyang(xy_xu\@foxmail.com)
	NAME: $program
	PATH: $0
        VERSION: v0.1	2017-10-15
NOTE
	cnv format:
	Chr    Start   End     Copy_Number
	1       755000  1290000 3

USAGE
	$program <options> cnv.file
	$guide_separator Basic $guide_separator
	--help			print help information
	--outDir <s>		script out Dir, default "$outDir"
	--N_bed <s>		N_bed bed file, default "$N_bed"

INFO

die $guide if (@ARGV == 0 || defined $help);

# Main
my %N_region;

open NB, $N_bed or die $!;
while (<NB>) {
	next if (/^#/);
	chomp;
	my @rows = split /\s+/;
	$rows[0] =~ s/chr//gi;
	$rows[0] = 23 if ($rows[0] =~ /X/i);
        $rows[0] = 24 if ($rows[0] =~ /Y/i);
	$N_region{$rows[0]}{$rows[1]} = $rows[2];
}
close NB;

open CNV, $ARGV[0] or die $!;
while (<CNV>) {
	if (/^#/) {
		print;
		next;
	}
	chomp;
	my @rows = split /\s+/;
	$rows[0] =~ s/chr//gi;
	$rows[0] = 23 if ($rows[0] =~ /X/i);
	$rows[0] = 24 if ($rows[0] =~ /Y/i);
	my $line = $_;
	my $total_intersect = 0;
	foreach my $start (keys %{$N_region{$rows[0]}}) {
		if (&overlap($rows[1], $rows[2], $start, $N_region{$rows[0]}{$start})) {
			$total_intersect += &overlap($rows[1], $rows[2], $start, $N_region{$rows[0]}{$start});
		}
	}
	if ($total_intersect) {
		my $size = $rows[2] - $rows[1];
		my $ratio = sprintf("%.4f", $total_intersect/$size);
		print "$line\t$ratio\n";
	} else {
		print "$line\t0\n";
	}
}
close CNV;


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
