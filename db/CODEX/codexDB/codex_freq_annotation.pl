#!/usr/bin/env perl
use strict;
use warnings;
use Cwd 'abs_path';
use File::Basename;
use Getopt::Long;
use Data::Dumper;

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
$cnvDB ||= "/HOME/cheerland_1/WORKSPACE/pipeline/exome/db/CODEX/cnv_private_annotation_db/cnv.20161222.db";

# Guide for program
my $guide_separator = "#" x 80;
my $program = basename(abs_path($0));
$program =~ s/\.pl//;
my $guide=<<INFO;
VER
	AUTHOR: xuxiangyang(xy_xu\@foxmail.com)
	NAME: $program
	PATH: $0
        VERSION: v0.1	2016-12-22
NOTE
	var.file format:
	chrY    25375656        27010717        0       0       1635.062        1
	the seventh column should be copy numbers
USAGE
	$program <options> var.file 
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
		foreach my $start (keys %{$interval{$row[0]}}) {
			if ($interval{$row[0]}{$start}{$row[6]} && &overlap($row[1], $row[2], $start, $interval{$row[0]}{$start}{$row[6]})) {
				$flag = 1;
				print "$line\t${$site{$row[0]}{$start}{$interval{$row[0]}{$start}{$row[6]}}{$row[6]}}[0]\t${$site{$row[0]}{$start}{$interval{$row[0]}{$start}{$row[6]}}{$row[6]}}[1]\n";
				last;
			}
		}
		if ($flag == 0) {
			print "$line\t-\t-\n";
		}
	} else {
		print "$line\t-\t-\n";	
	}

}
close VAR;

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

