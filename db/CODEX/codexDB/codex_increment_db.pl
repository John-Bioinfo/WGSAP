#!/usr/bin/env perl
#use strict;
use warnings;
use Cwd 'abs_path';
use File::Basename;
use Getopt::Long;
use Data::Dumper;

# Global variable
my ($help, $outDir, $outFile, $inputFile);

# Get Parameter
GetOptions(
	"h|help" => \$help,	
	"outDir=s" => \$outDir,
	"outFile=s" => \$outFile,
	"inputFile=s" => \$inputFile,
);

my $tmpDir = `pwd`;
chomp $tmpDir;
$outDir ||= "$tmpDir";

my($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time());
my $format_time=sprintf("%d%d%d", $year+1900, $mon+1, $mday); 
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
        VERSION: v0.1	2016-12-20
NOTE
	1. file in var.lst should be in absolute path
	2. X replace by 23, Y replace by 24 on the output
	3. this program only add var file to database, can't combine database
	4. input file format should be like: chr1    212533975       215848603       0       0       3314.629        0       181     1293.282

USAGE
	$program <options> raw.db [var.lst] 
	$guide_separator Basic $guide_separator
	--help			print help information
	--outDir <s>		script out Dir, default "$outDir"
	--outFile <s>		File name for program output, default "$outFile"
	--inputFile <s>		File for program input, like a.txt,b.txt......

INFO
# Call guide
die $guide if (@ARGV == 0 || defined $help);

# Program check

# Main
my ($db, $list) = @ARGV;

my (%site, %interval, $Data_source, $raw_samples, $Add_sample_number);

open DB, $db or die $!;
while (<DB>) {
	chomp;
	$Data_source = $_ if(/^#Data/i);
	if ($Data_source) {
		$Data_source =~ m/from (\d+) WES/;
        	$raw_samples = $1;
	}
	next if(/^#/);
	my @row = split /\s+/;
	$row[0] =~ s/chr//i;
	$row[0] = 23 if ($row[0] =~ /X/i);
	$row[0] = 24 if ($row[0] =~ /Y/i);
	$interval{$row[0]}{$row[1]}{$row[3]} = $row[2];
	push @{$site{$row[0]}{$row[1]}{$row[2]}{$row[3]}}, ($row[4], $row[5]);
}
close DB;

#print Dumper \%site;

if ($inputFile) {
	my @files = split ",", $inputFile;
	$Add_sample_number = @files + $raw_samples if (defined $raw_samples);
	foreach my $input (@files) {	
		open INPUT, $input or die $!;
		while (<INPUT>) {
			next if(/^#/);
			chomp;
			my @row = split /\s+/;
			$row[0] =~ s/chr//i;
			$row[0] = 23 if ($row[0] =~ /X/i);
			$row[0] = 24 if ($row[0] =~ /Y/i);
			if ($site{$row[0]} && $interval{$row[0]}) {
				my $flag = 0;
				foreach my $start (keys %{$interval{$row[0]}}) {
					if ($interval{$row[0]}{$start}{$row[6]} && &overlap($row[1], $row[2], $start, $interval{$row[0]}{$start}{$row[6]})) {
						$flag = 1;
						${$site{$row[0]}{$start}{$interval{$row[0]}{$start}{$row[6]}}{$row[6]}}[0]++;
						${$site{$row[0]}{$start}{$interval{$row[0]}{$start}{$row[6]}}{$row[6]}}[1] = "${Add_sample_number}WES";
						last;
					}
				}
				if ($flag == 0) {
					${$site{$row[0]}{$row[1]}{$row[2]}{$row[6]}}[0] = 1;
					${$site{$row[0]}{$row[1]}{$row[2]}{$row[6]}}[1] = "${Add_sample_number}WES";
					$interval{$row[0]}{$row[1]}{$row[6]} = $row[2];
				}
			} else {
				${$site{$row[0]}{$row[1]}{$row[2]}{$row[6]}}[0] = 1;
				${$site{$row[0]}{$row[1]}{$row[2]}{$row[6]}}[1] = "${Add_sample_number}WES";
				$interval{$row[0]}{$row[1]}{$row[6]} = $row[2];		
			}
		}
		close INPUT;
	}
}

if ($list) {
	$Add_sample_number = `grep -v "#" $list | wc -l`;
	chomp $Add_sample_number;
	$Add_sample_number += $raw_samples if (defined$raw_samples);
	open LIST, $list or die $!;
	while (<LIST>) {
		next if(/^#/);
		chomp;
		my $file = $_;
		open FILE, $file or die $!;
		while (<FILE>) {
			next if(/^#/);
			chomp;
			my @row = split /\s+/;
			$row[0] =~ s/chr//i;
			$row[0] = 23 if ($row[0] =~ /X/i);
			$row[0] = 24 if ($row[0] =~ /Y/i);
			if ($site{$row[0]} && $interval{$row[0]}) {
				my $flag = 0;
				foreach my $start (keys %{$interval{$row[0]}}) {
					if ($interval{$row[0]}{$start}{$row[6]} && &overlap($row[1], $row[2], $start, $interval{$row[0]}{$start}{$row[6]})) {
						$flag = 1;
						${$site{$row[0]}{$start}{$interval{$row[0]}{$start}{$row[6]}}{$row[6]}}[0]++;
						${$site{$row[0]}{$start}{$interval{$row[0]}{$start}{$row[6]}}{$row[6]}}[1] = "${Add_sample_number}WES";
						last;
					}
				}
				if ($flag == 0) {
					${$site{$row[0]}{$row[1]}{$row[2]}{$row[6]}}[0] = 1;
					${$site{$row[0]}{$row[1]}{$row[2]}{$row[6]}}[1] = "${Add_sample_number}WES";
					$interval{$row[0]}{$row[1]}{$row[6]} = $row[2];
				}
			} else {
				${$site{$row[0]}{$row[1]}{$row[2]}{$row[6]}}[0] = 1;
				${$site{$row[0]}{$row[1]}{$row[2]}{$row[6]}}[1] = "${Add_sample_number}WES";
				$interval{$row[0]}{$row[1]}{$row[6]} = $row[2];
			}
		}	
	}	close FILE;
	close LIST;
}

open OUT, ">$outFile" or die $!;
print OUT "#Data comes from $Add_sample_number WES samples\n" if ($Add_sample_number); 
print OUT "#Chr\tStart\tEnd\tCopy_Number\tFreq\tSample_Number\n";

foreach my $chr (sort {$a <=> $b} keys %site) {
	foreach my $start (sort {$a <=> $b} keys %{$site{$chr}}) {
		foreach my $end (sort {$a <=> $b} keys %{$site{$chr}{$start}}) {
			foreach my $cn (sort {$a <=> $b} keys %{$site{$chr}{$start}{$end}}) {
					$site{$chr}{$start}{$end}{$cn}[1] =~ s/\d+WES/${Add_sample_number}WES/i if ($Add_sample_number);
					print OUT "$chr\t$start\t$end\t$cn\t$site{$chr}{$start}{$end}{$cn}[0]\t$site{$chr}{$start}{$end}{$cn}[1]\n";
			}
		}
	}

}
close OUT;

sub overlap {
	my ($s, $e, $d_s, $d_e) = @_;
	my $len = $e - $s;
	my $d_len = $d_e - $d_s;
	my $intersect;
	if ($s <= $d_s && $e >= $d_e) {
		$intersect = $d_len;
	} elsif ($e > $d_s && $e <= $d_e && $s < $d_s) {
		$intersect = $e - $d_s;	
	} elsif ($e > $d_s && $e <= $d_e && $s >= $d_s)  {
		$intersect = $len;
	} elsif ($e > $d_e && $s >= $d_s && $s < $d_e) {
		$intersect = $d_e - $s;
	}
	if ($intersect && ($intersect/$len > 0.8 or $intersect/$d_len > 0.8)) {
		return 1;
	} else {	
		return 0;
	}
}
