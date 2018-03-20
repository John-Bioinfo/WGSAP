#!/usr/bin/env perl
use strict;
use warnings;
use Cwd 'abs_path';
use File::Basename;
use Getopt::Long;
use Data::Dumper;

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
$gene ||= "/HOME/cheerland_1/WORKSPACE/pipeline/exome/db/ucsc/cnv/cnvGene.bed";

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
	$program <options> var.file
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
	$region{$rows[0]}{$rows[1]} = $rows[2];
	$geneInfo{$rows[0]}{$rows[1]}{$rows[2]} = $rows[6];
}
close GN;

open VAR, $ARGV[0] or die $!;
while (<VAR>) {
	next if (/^#/);
	chomp;
	my @rows = split /\s+/;
	$rows[0] =~ s/chr//gi;
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
        if ($intersect && ($intersect/$len > 0.1 or $intersect/$d_len > 0.1)) {
                return 1;
        } else {
                return 0;
        }
}

