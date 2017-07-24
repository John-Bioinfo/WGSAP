#!/usr/bin/env perl
use strict;
use warnings;

$/ = '>';
<>;
while (<>) {
	chomp;
	my @arr = split /\n/;
	my $head = shift @arr;
	my $seq = join "", @arr;
	$seq =~ s/\s*//g;
	$head =~ m/([^:]*):(\d+)-\d+/;
	my $chr = $1;
	my $pos = $2;
	my @arr2 = split "", $seq;
	foreach my $base (@arr2) {
		$pos++;
		print "$chr\t$pos\t$base\n";
	}
}
