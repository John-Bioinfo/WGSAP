#!/bin/env perl
use strict;
use warnings;

$/ = '>';
<>;
while (<>) {
	chomp;
	$_ =~ m/(\S+)\n/;
	my $prefix = $1;
	#print "$prefix:\n>$_";
	open OP, ">$prefix.fa" or die $!;
	print OP ">$_";
	close OP;
}
