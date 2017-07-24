#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Long;

=head1 Description

	genome_stat.pl

	This script is used to get genome information.

=head1 Version

	Author: Xiangyang Xu, xuxiangyang@genomics.cn

	Version: 0.1,  Date: 2016-1-11

=head1 Usage

	perl genome_stat.pl  [options]  genome.fa > out.stat  
	Options:
	-help   Print this information
        

=head1 Input

	genome.fa:
	sequences in fasta for genome

=head1 Example

	perl genome_stat.pl genome.fa > out.stat 
        
=cut

my $help;

GetOptions(
        "help|h" => \$help,
);


die `pod2text $0` if ($help || @ARGV == 0);

my ($file, $out) = @ARGV;

$out ||= "genome.stat";

my ($genome, $N, $gap, $at, $gc, $gc_rate);

if ($file =~ /gz$/) {
	open F, "gzip -dc $file |" or die "$!\n";
} else {
	open F, $file or die $!;
}
$/ = '>';
<F>;
while (<F>) {
	chomp;
	my @arr = split /\n/;
	my $id = shift @arr;
	$id =~ s/(\S+)\s+/$1/;
	my $seq = join "", @arr;
	$seq =~ s/\s+//g;
	my $tmp = $seq;
	$genome += length $seq;
	$N += $tmp =~ tr/nN//;
	while ($seq =~ m/(n+)/gi) {
		$gap++;
		my $gap_len = length $1;
		#print "$gap\t$gap_len\n";
	}
	$gc += $seq =~ tr/gcGC/gcGC/;
        $at += $seq =~ tr/atAT/atAT/;
}
close F;

$gc_rate = sprintf("%.2f%%", $gc / ($gc+$at) * 100);

if ($gap) {
	print "genome_sie:$genome\ngc_rate:$gc_rate\nN_number:$N\nGap_number:$gap\n";
} else {
	print "genome_sie:$genome\ngc_rate:$gc_rate\n";
}
