#!/usr/bin/perl

use warnings;
use strict;
use FindBin qw($Bin);
use Getopt::Long;
use Data::Dumper;
use File::Basename;

my ($bamfile,$outdir,$bin,$help);

GetOptions(
		"i:s"=>\$bamfile,
		"o:s"=>\$outdir,
		"b:s"=>\$bin,
		"h"=>\$help,
		);

my $usage=<<USAGE;
usage:perl $0
		-i <bamfile>
		-b <program dir>
		-o <outdir>
		-h help
USAGE

die $usage if (!$bamfile || $help || !$outdir);

my $Initial_bases_on_genome=3137161264;
my $Total_effective_reads=0;
my $Total_effective_yield=0;
my $Average_read_length=0;
my $Base_covered_on_genome=0;
my $Coverage_of_genome_region=0;
my $Fraction_of_genome_covered_with_at_least_20x=0;
my $Fraction_of_genome_covered_with_at_least_10x=0;
my $Fraction_of_genome_covered_with_at_least_4x=0;
# Add by xy_xu
my $clean_reads;
my $mapped_reads;
my $dup_reads;
my $mapping_rate;
my $dup_rate;

my %hash=(
chrM => 16571,
chr1 => 249250621,
chr2 => 243199373,
chr3 => 198022430,
chr4 => 191154276,
chr5 => 180915260,
chr6 => 171115067,
chr7 => 159138663,
chr8 => 146364022,
chr9 => 141213431,
chr10 => 135534747,
chr11 => 135006516,
chr12 => 133851895,
chr13 => 115169878,
chr14 => 107349540,
chr15 => 102531392,
chr16 => 90354753,
chr17 => 81195210,
chr18 => 78077248,
chr19 => 59128983,
chr20 => 63025520,
chr21 => 48129895,
chr22 => 51304566,
chrX => 155270560,
chrY => 59373566,
);


$bin ||= "/datapool/home/xuxiangyang/pipeline/exome/bin";
open BAM,"$bin/samtools_v0.1.18/samtools view -X $bamfile | " or die $!;
mkdir $outdir unless -d $outdir;
while(<BAM>)
{
	chomp;
	$clean_reads++;	
	my $fflag=(split /\t/,$_)[1];
	$mapped_reads++ if ($fflag !~ /u/);
	$dup_reads++ if ($fflag =~ /d/ && $fflag !~ /u/);
	$Total_effective_reads++ if ($fflag !~ /d|u/); 

}
close BAM;

# Add by xy_xu
$mapping_rate=$mapped_reads/$clean_reads;
$dup_rate=$dup_reads/$mapped_reads;

`$bin/samtools_v0.1.18/samtools depth $bamfile >$outdir/whole_genome.depth`;
$Total_effective_yield=`awk '{total+=\$3};END{print total}' $outdir/whole_genome.depth`;
chomp $Total_effective_yield;
$Average_read_length=$Total_effective_yield/$Total_effective_reads;

my $tmp1=`awk '\$3 >=20 {total1++};\$3 >=10 {total2++};\$3 >=4 {total3++};END{print total1"\t"total2"\t"total3}' $outdir/whole_genome.depth`;
chomp($tmp1);
my @info1;
@info1=split /\t/,$tmp1;
if(defined($info1[0]) or $info1[0]=0)
{
$Fraction_of_genome_covered_with_at_least_20x=$info1[0]/$Initial_bases_on_genome;
}
if(defined($info1[1]) or $info1[1]=0)
{
$Fraction_of_genome_covered_with_at_least_10x=$info1[1]/$Initial_bases_on_genome;
}
if(defined($info1[2]) or $info1[2]=0)
{
$Fraction_of_genome_covered_with_at_least_4x=$info1[2]/$Initial_bases_on_genome;
}



my $name=basename($bamfile);
my $sample=(split /\./,$name)[0];
open STAT,">$outdir/information.xls" or die $!;
print STAT "Sample\t$sample\n";
print STAT "Total effective reads\t$Total_effective_reads\n";
printf STAT "Total effective yield(Mb)\t%.2f\n",$Total_effective_yield/1000000;
printf STAT "Average read length(bp)\t%.2f\n",$Average_read_length;
#print STAT "Base covered on genome\t$Base_covered_on_genome\n";
#printf STAT "Coverage of genome region\t%.1f%%\n",100*$Coverage_of_genome_region;
printf STAT "Fraction of genome covered with at least 20x\t%.1f%%\n",100*$Fraction_of_genome_covered_with_at_least_20x;
printf STAT "Fraction of genome covered with at least 10x\t%.1f%%\n",100*$Fraction_of_genome_covered_with_at_least_10x;
printf STAT "Fraction of genome covered with at least 4x\t%.1f%%\n",100*$Fraction_of_genome_covered_with_at_least_4x;
print STAT "Mapping rate\t",sprintf("%.2f%%",100*$mapping_rate),"\n";
print STAT "Duplicate rate\t",sprintf("%.2f%%",100*$dup_rate),"\n";
close STAT;

my %dep=();
my %cov=();
open IN,"$outdir/whole_genome.depth" or die "Can't open the $outdir/whole_genome.depth:$!";
while (<IN>)
{
	chomp;
	my ($chr,$dd)=(split /\t/,$_)[0,2];
	$cov{$chr}++;
	$dep{$chr}+=$dd;
}
close IN;
open OUT,">$outdir/chrall.stat" or die $!;
print OUT "Chr\tCoverage\tDepth\n";
foreach my $ch (sort keys %hash)
{
	my $cp = 100*$cov{$ch}/$hash{$ch};
	my $dp = $dep{$ch}/$hash{$ch};
	printf OUT "$ch\t%.2f%%\t%.2f\n",$cp,$dp;
}
close OUT;
