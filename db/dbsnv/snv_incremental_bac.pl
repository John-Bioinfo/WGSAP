#!/usr/bin/env perl
#use strict;
use warnings;
use Cwd 'abs_path';
use File::Basename;
use Getopt::Long;
use Data::Dumper;
use POSIX;

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

my $format_time = strftime("%Y%m%d",localtime()); 
$outFile ||= "snv.$format_time.db";

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
	1. file in var.lst should be in absolute path
	2. X replace by 23, Y replace by 24 on the output
	3. this program only add var file to database, can't combine database
	4. input file format should be like: 1	12318	12318	C	A	OtherInformation	
ADD
	1. redefine Sample_Number by site;
	2. filter site when Ref equal to Alt;

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

my (%site, %total, $Data_source, $raw_samples, $Add_sample_number, %mark);

open DB, $db or die $!;
while (<DB>) {
	chomp;
	$Data_source = $_ if(/^#Data/i);
	$Data_source =~ m/\+ (\d+) WES/;
        $raw_samples = $1;
	next if(/^#/);
	my @row = split /\s+/;
	$site{$row[0]}{$row[1]}{$row[2]}{$row[3]}{$row[4]} = $row[5];
	$mark{$row[0]}{$row[1]}{$row[2]}{$row[3]} = $row[7];
	$total{$row[0]}{$row[1]}{$row[2]}{$row[3]} = $row[6];
}
close DB;

if ($inputFile) {
	my @files = split ",", $inputFile;
	$Add_sample_number = @files + $raw_samples if ($raw_samples);
	foreach my $input (@files) {	
		open INPUT, $input or die $!;
		while (<INPUT>) {
			next if(/^#/);
			my @row = split /\s+/;
			$row[0] = 23 if ($row[0] =~ /X/i);
			$row[0] = 24 if ($row[0] =~ /Y/i);
			if ($site{$row[0]}{$row[1]}{$row[2]}{$row[3]}{$row[4]}) {
				$site{$row[0]}{$row[1]}{$row[2]}{$row[3]}{$row[4]}++;
			} else {
				$site{$row[0]}{$row[1]}{$row[2]}{$row[3]}{$row[4]} = 1;
			}
			if ($mark{$row[0]}{$row[1]}{$row[2]}{$row[3]}) {
				$total{$row[0]}{$row[1]}{$row[2]}{$row[3]}++;
				if ($mark{$row[0]}{$row[1]}{$row[2]}{$row[3]} eq "1K") {
                                        $mark{$row[0]}{$row[1]}{$row[2]}{$row[3]} = "1K+${Add_sample_number}WES";
                                }
			} else {
				$total{$row[0]}{$row[1]}{$row[2]}{$row[3]} = 1;
				$mark{$row[0]}{$row[1]}{$row[2]}{$row[3]} = "${Add_sample_number}WES";
			}

		}
		close INPUT;
	}
}

if ($list) {
	$Add_sample_number = `grep -v "#" $list | wc -l`;
	chomp $Add_sample_number;
	$Add_sample_number += $raw_samples if ($raw_samples);
	open LIST, $list or die $!;
	while (<LIST>) {
		next if(/^#/);
		chomp;
		my $file = $_;
		open FILE, $file or die $!;
		while (<FILE>) {
			next if(/^#/);
			my @row = split /\s+/;
			$row[0] = 23 if ($row[0] =~ /X/i);
			$row[0] = 24 if ($row[0] =~ /Y/i);
			if ($site{$row[0]}{$row[1]}{$row[2]}{$row[3]}{$row[4]}) {
				$site{$row[0]}{$row[1]}{$row[2]}{$row[3]}{$row[4]}++;
			} else {
				$site{$row[0]}{$row[1]}{$row[2]}{$row[3]}{$row[4]} = 1;
			}
			if ($mark{$row[0]}{$row[1]}{$row[2]}{$row[3]}) {
				$total{$row[0]}{$row[1]}{$row[2]}{$row[3]}++;
				if ($mark{$row[0]}{$row[1]}{$row[2]}{$row[3]} eq "1K") {
                                        $mark{$row[0]}{$row[1]}{$row[2]}{$row[3]} = "1K+${Add_sample_number}WES";
                                }
			} else {
				$total{$row[0]}{$row[1]}{$row[2]}{$row[3]} = 1;
				$mark{$row[0]}{$row[1]}{$row[2]}{$row[3]} = "${Add_sample_number}WES";
			}
		}	
	}	close FILE;
	close LIST;
}

open OUT, ">$outFile" or die $!;
print OUT "#Data comes from about 1052 children(1K) + $Add_sample_number WES samples\n"; 
print OUT "#Chr\tStart\tEnd\tRef\tAlt\tFreq\tTotal\tSample_Number\n";

foreach my $chr (sort {$a <=> $b} keys %site) {
	foreach my $start (sort {$a <=> $b} keys %{$site{$chr}}) {
		foreach my $end (sort {$a <=> $b} keys %{$site{$chr}{$start}}) {
			foreach my $ref (sort {$a cmp $b} keys %{$site{$chr}{$start}{$end}}) {
				foreach my $alt (sort {$a cmp $b} keys %{$site{$chr}{$start}{$end}{$ref}}) {
					$mark{$chr}{$start}{$end}{$ref} =~ s/\d+WES/${Add_sample_number}WES/i;
					print OUT "$chr\t$start\t$end\t$ref\t$alt\t$site{$chr}{$start}{$end}{$ref}{$alt}\t$total{$chr}{$start}{$end}{$ref}\t$mark{$chr}{$start}{$end}{$ref}\n";
				}
			}
		}
	}

}
close OUT;
