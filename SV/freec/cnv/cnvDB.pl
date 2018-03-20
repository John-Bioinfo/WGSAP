#!/usr/bin/env perl
#use strict;
use warnings;
use Cwd 'abs_path';
use File::Basename;
use Getopt::Long;
use Data::Dumper;
use FindBin qw($Bin);
use POSIX;


# Global variable
my ($help, $outDir, $outFile);

# Get Parameter
GetOptions(
	"h|help" => \$help,	
	"outDir=s" => \$outDir,
	"outFile=s" => \$outFile,
);

my $tmpDir = `pwd`;
chomp $tmpDir;
$outDir ||= "$tmpDir";
my $format_time = strftime("%Y%m%d",localtime());
$outFile ||= "cnv.$format_time.db";

# Guide for program
my $guide_separator = "#" x 80;
my $program = basename(abs_path($0));
$program =~ s/\.pl//;
my $guide=<<INFO;
VER
	AUTHOR: xuxiangyang(xy_xu\@foxmail.com)
	NAME: $program
	PATH: $0
        VERSION: v0.1	2017-10-11
NOTE
	1. file in cnv.lst should be in absolute path
	2. cnv.lst format: /datapool/home/xuxiangyang/project/CNV/20171009/CNV/DMPL17014/DMPL17014.sort.bam_CNVs XY
	2. X replace by 23, Y replace by 24 on the output
	3. this program only add var file to database, can't combine database
	4. input file format should be like: 1       24252000        24362000        1

USAGE
	$program <options> raw.db cnv.lst 
	$guide_separator Basic $guide_separator
	--help			print help information
	--outDir <s>		script out Dir, default "$outDir"
	--outFile <s>		File name for program output, default "$outFile"

INFO
# Call guide
die $guide if (@ARGV == 0 || defined $help);

# Program check

# Main
my ($db, $list) = @ARGV;

my (%site, %interval, $Data_source, $raw_samples, $total_sample_number);

open DB, $db or die $!;
while (<DB>) {
	chomp;
	$Data_source = $_ if(/^#Data/i);
	if ($Data_source) {
		$Data_source =~ m/from (\d+) WGS/;
        	$raw_samples = $1;
	}
	next if(/^#/);
	my @row = split /\s+/;
	$row[0] =~ s/chr//i;
	$row[0] = 23 if ($row[0] =~ /X/i);
	$row[0] = 24 if ($row[0] =~ /Y/i);
	$interval{$row[0]}{$row[1]}{$row[3]} = $row[2]; # chr -> start -> CopyNumber = end
	push @{$site{$row[0]}{$row[1]}{$row[2]}{$row[3]}}, ($row[4], $row[5]); # chr -> start -> end -> CopyNumber = (Freq, Sample_Number)
}
close DB;

if ($list) {
	$total_sample_number = `grep -v "#" $list | wc -l`;
	chomp $total_sample_number;
	$total_sample_number += $raw_samples if (defined $raw_samples);
	open LIST, $list or die $!;
	while (<LIST>) {
		next if(/^#/);
		chomp;
		my @arr = split /\s+/;
		my $file = $arr[0];
		open FILE, $file or die $!;
		while (<FILE>) {
			next if(/^#/);
			chomp;
			my @row = split /\s+/;
			$row[0] =~ s/chr//i;
			$row[0] = 23 if ($row[0] =~ /X/i);
			$row[0] = 24 if ($row[0] =~ /Y/i);
			# 根据性别过滤掉性染色体上的拷贝数变异
			next if($arr[1] && $arr[1] eq "XX" && $row[0] == 24);
			if ($site{$row[0]} && $interval{$row[0]}) {
				my $flag = 0;
				# 循环遍历数据库，判断区间是否与数据库有重合
				foreach my $start (keys %{$interval{$row[0]}}) {
					if ($interval{$row[0]}{$start}{$row[3]} && &overlap($row[1], $row[2], $start, $interval{$row[0]}{$start}{$row[3]})) {
						$flag = 1;
						# freq统计异常测试
						#if ($start == 43422000 && $interval{$row[0]}{$start}{$row[3]} == 47453000) {
						#	print "$file\t${$site{$row[0]}{$start}{$interval{$row[0]}{$start}{$row[3]}}{$row[3]}}[0]\t$row[1]\t$row[2]\n";
						#}
						${$site{$row[0]}{$start}{$interval{$row[0]}{$start}{$row[3]}}{$row[3]}}[0]++;
						${$site{$row[0]}{$start}{$interval{$row[0]}{$start}{$row[3]}}{$row[3]}}[1] = "${total_sample_number}WGS";
						last;
					}
				}
				# 区间在数据库没有记录，在数据库中增加新的记录
				if ($flag == 0) {
					${$site{$row[0]}{$row[1]}{$row[2]}{$row[3]}}[0] = 1;
					${$site{$row[0]}{$row[1]}{$row[2]}{$row[3]}}[1] = "${total_sample_number}WGS";
					$interval{$row[0]}{$row[1]}{$row[3]} = $row[2];
				}
			# 初始化数据库
			} else {
				${$site{$row[0]}{$row[1]}{$row[2]}{$row[3]}}[0] = 1;
				${$site{$row[0]}{$row[1]}{$row[2]}{$row[3]}}[1] = "${total_sample_number}WGS";
				$interval{$row[0]}{$row[1]}{$row[3]} = $row[2];
			}
		}	
	}	close FILE;
	close LIST;
}

open OUT, ">$outFile" or die $!;
print OUT "#Data comes from $total_sample_number WGS samples\n" if ($total_sample_number); 
print OUT "#Chr\tStart\tEnd\tCopy_Number\tFreq\tSample_Number\n";

foreach my $chr (sort {$a <=> $b} keys %site) {
	foreach my $start (sort {$a <=> $b} keys %{$site{$chr}}) {
		foreach my $end (sort {$a <=> $b} keys %{$site{$chr}{$start}}) {
			foreach my $cn (sort {$a <=> $b} keys %{$site{$chr}{$start}{$end}}) {
					# 校正统计样品数目
					$site{$chr}{$start}{$end}{$cn}[1] =~ s/\d+WGS/${total_sample_number}WGS/i if ($total_sample_number);
					print OUT "$chr\t$start\t$end\t$cn\t$site{$chr}{$start}{$end}{$cn}[0]\t$site{$chr}{$start}{$end}{$cn}[1]\n";
			}
		}
	}

}
close OUT;

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
