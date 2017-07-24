#!/usr/bin/perl
use strict;
use warnings;

while (<>) {
	next if (/^#/);
	my @arr = split /\t/;
	$arr[0] =~ s/chr//i;
	my ($alt, $ref, $variantType);
	if ($arr[-1] =~ /alt=([^;]*).*ref=([^;]*).*variantType=([^;]*).*/) {
		$alt = $1;
		$ref = $2;
		$variantType = $3;
	}
	#print "$arr[0]\t$arr[3]\t$arr[4]\t$ref\t$alt\t$variantType\n";
	next if (length $ref > 1 && length $alt > 1);
	if (length $ref == length $alt) {
		print "$arr[0]\t$arr[3]\t$arr[4]\t$ref\t$alt\t$variantType\n";
	} elsif (length $ref < length $alt) {
		$alt =~ s/$ref//;
		$ref = "-";
		print "$arr[0]\t$arr[3]\t$arr[4]\t$ref\t$alt\t$variantType\n";
	} else {
		$ref =~ s/$alt//;
		$alt = "-";
		my $start = $arr[3] + length($alt);
		print "$arr[0]\t$start\t$arr[4]\t$ref\t$alt\t$variantType\n";
	}
}
