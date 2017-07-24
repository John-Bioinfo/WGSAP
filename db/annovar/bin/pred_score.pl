#!/usr/bin/perl
use strict;
use warnings;

while (<>) {
	next if(/^#/);
	chomp;
	my $line = $_;
	my @arr = split /\t/;
	my ($sift, $hdiv, $hvar, $mt);

	if ($arr[-9] eq "D") {
		$sift = 2;
	} elsif ($arr[-9] eq "T") {
		$sift = 0;
	} else {
		$sift = 1;
	}

	if ($arr[-8] eq "D" or $arr[-8] eq "P") {
                $hdiv = 2;
        } elsif ($arr[-8] eq "B") {
                $hdiv = 0;
        } else {
                $hdiv = 1;
        }

	if ($arr[-7] eq "D" or $arr[-7] eq "P") {
                $hvar = 2;
        } elsif ($arr[-7] eq "B") {
                $hvar = 0;
        } else {
                $hvar = 1;
        }

	if ($arr[-5] eq "D" or $arr[-5] eq "A") {
                $mt = 2;
        } elsif ($arr[-5] eq "N" or $arr[-5] eq "P") {
                $mt = 0;
        } else {
                $mt = 1;
        }
	my $total = $sift + $hdiv + $hvar + $mt;
	#print "$line\t$sift\t$hdiv\t$hvar\t$mt\t$total\n";
	print "$line\t$total\n";
}
