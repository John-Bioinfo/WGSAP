#!/usr/bin/perl
use strict;
use warnings;

my %hash;

while (<>) {
	next if (/^#/);
	chomp;
	my @arr = split /\t/;
	my $gene = shift @arr;
	my $unit = join "+", @arr;
	if ($hash{$gene}) {
		$hash{$gene} .= "&" . $unit;
	} else {
		$hash{$gene} = $unit;
	}
}

foreach my $key (sort {$a cmp $b} keys %hash) {
	print "$key\t$hash{$key}\n";
}
