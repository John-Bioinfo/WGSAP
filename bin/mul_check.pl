#!/usr/bin/perl
use strict;
use warnings;

my $i;

while (<>) {
	$i++;
	open F, ">data_$i.txt" or die $!;
	print F $_;
	close F;
	system("md5sum -c data_$i.txt > data_$i.check &") == 0 or die $!;
}
