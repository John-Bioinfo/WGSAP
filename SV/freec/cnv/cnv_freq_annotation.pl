#!/usr/bin/env perl
use strict;
use warnings;
use Cwd 'abs_path';
use File::Basename;
use Getopt::Long;
use Data::Dumper;
use FindBin qw($Bin);

# Global variable
my ($help, $outDir, $cnvDB);

# Get Parameter
GetOptions(
	"h|help" => \$help,	
	"outDir=s" => \$outDir,
	"cnvDB=s" => \$cnvDB,
);

my $tmpDir = `pwd`;
chomp $tmpDir;
$outDir ||= "$tmpDir";
$cnvDB ||= "$Bin/cnv.20171013.db";

# Guide for program
my $guide_separator = "#" x 80;
my $program = basename(abs_path($0));
$program =~ s/\.pl//;
my $guide=<<INFO;
VER
	AUTHOR: xuxiangyang(xy_xu\@foxmail.com)
	NAME: $program
	PATH: $0
        VERSION: v0.2	2017-10-11
NOTE
	db format:
	Chr    Start   End     Copy_Number     Freq    Sample_Number
	1       755000  1290000 3       3       19WGS
	1       2354000 3640000 3       7       19WGS
	cnv.file format:
	Chr	Start	End	CopyNumber
	1       755000  1290000 3
USAGE
	$program <options> cnv.file 
	$guide_separator Basic $guide_separator
	--help			print help information
	--outDir <s>		script out Dir, default "$outDir"
	--cnvDB <s>		cnv data base, default "$cnvDB"

INFO

die $guide if (@ARGV == 0 || defined $help);

# Main
my ($var) = @ARGV;
my (%site, %interval);

open DB, $cnvDB or die $!;
while (<DB>) {
        chomp;
        next if(/^#/);
        my @row = split /\s+/;
        $interval{$row[0]}{$row[1]}{$row[3]} = $row[2];
        push @{$site{$row[0]}{$row[1]}{$row[2]}{$row[3]}}, ($row[4], $row[5]);
}
close DB;

open VAR, $var or die $!;
while (<VAR>) {
	if(/^#/) {
		print;
		next;
	}
	chomp;
	my @row = split /\s+/;
	my $line = $_;
	$row[0] =~ s/chr//i;
	$row[0] = 23 if ($row[0] =~ /X/i);
	$row[0] = 24 if ($row[0] =~ /Y/i);
	if ($site{$row[0]} && $interval{$row[0]}) {
		my $flag = 0;
		# 遍历数据库是否存在此cnv
		foreach my $start (keys %{$interval{$row[0]}}) {
			if ($interval{$row[0]}{$start}{$row[3]} && &overlap($row[1], $row[2], $start, $interval{$row[0]}{$start}{$row[3]})) {
				$flag = 1;
				print "$line\t${$site{$row[0]}{$start}{$interval{$row[0]}{$start}{$row[3]}}{$row[3]}}[0]\t${$site{$row[0]}{$start}{$interval{$row[0]}{$start}{$row[3]}}{$row[3]}}[1]\n";
				#print "$start\t$interval{$row[0]}{$start}{$row[3]}\n";
				last;
			}
		}
		# 数据库不存在此cnv
		if ($flag == 0) {
			print "$line\t-\t-\n";
		}
	# 数据库没有该条染色体的记录
	} else {
		print "$line\t-\t-\n";	
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
	# 目标区间位于该区间内测
	} elsif ($e >= $db_e && $s <= $db_s) {
		$intersect = $db_len;
	} 
	if ($intersect && ($intersect/$len > 0.5 or $intersect/$db_len > 0.5) && (&max_min_ratio($len, $db_len) < 2)) {
		return 1;
	} else {	
		return 0;
	}
}

sub max_min_ratio {
	my ($value1, $value2) = @_;
	my ($max, $min);	 	
	if ($value1 >= $value2) {
		$max = $value1;
		$min = $value2;
	} else {
		$max = $value2;
		$min = $value1;
	}
	my $ratio = $max/$min;
	return $ratio;
}
