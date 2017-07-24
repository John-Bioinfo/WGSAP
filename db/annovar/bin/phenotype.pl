#!/usr/bin/perl
use strict;
use warnings;

my ($input, $db) = @ARGV;

my %hash;

open IP, $input or die $!;
open DB, $db or die $!;

while (<DB>) {
	next if (/^#/);
	chomp;
	my @arr = split /\t/;
	$hash{$arr[0]} = $arr[1];
} 
close DB;


while (<IP>) {
	next if (/^#/);
        chomp;
	my @arr = split /\t/;
	if ($hash{$arr[14]}) {
		print "$_\t$hash{$arr[14]}\n";
	} else {
		print "$_\t-\n";
	}
} 
close IP;
