#!/usr/bin/perl
use strict;
use warnings;

while (<>) {
	next if (/^#/);
	my @arr = split /\t/;
	print "$.\t$_"  unless ($arr[0] && $arr[1] && $arr[2] && $arr[3]);
}
