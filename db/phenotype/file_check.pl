#!/usr/bin/perl
use strict;
use warnings;

while (<>) {
	next if (/^#/);
	print "$.\t$_"  if($_ !~ /^\w+(\t.*){0,3}/);
}
