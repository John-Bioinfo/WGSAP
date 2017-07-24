#!/usr/bin/env perl
use strict;
use warnings;
use FindBin qw($Bin);

open EXOME,"$ARGV[0].exonic_variant_function";
open ALL,"$ARGV[0].variant_function";
open OUT,">$ARGV[0].all_variant_function";

my %hash=();

while(<EXOME>){
	chomp;
	my @row=split /\t/,$_;
	$row[3]=~s/chr//i;
	$hash{"$row[3]\t$row[4]\t$row[5]"}="$row[1]\t$row[2]";

}
close EXOME;

while(<ALL>){
        chomp;
        my @row=split /\t/,$_;
	$row[2]=~s/chr//i;
	if($row[0] eq "exonic"){
		for(my $i=2;$i<@row;$i++){
			print OUT "$row[$i]\t";
	
		}
		if(@row<14){
	                for(my $i=@row;$i<14;$i++){
        	                print OUT "-\t";
	                }
		}
		print OUT "exonic\t".$hash{"$row[2]\t$row[3]\t$row[4]"}."\n";
		next;
	}
        my $temp1=shift @row;
	my $temp2=shift @row;
        foreach my $one(@row){
                print OUT "$one\t";
        
        }
                if(@row<12){
                        for(my $i=@row;$i<12;$i++){
                                print OUT "-\t";
                        }
                }

	print OUT "$temp1\t-\t$temp2";
	
        print OUT "\n";

}
close ALL;
close OUT;

my %len=();

open VA, "$ARGV[0].all_variant_function" or die $!;
open TP, ">$ARGV[0].all_variant_function.tmp" or die $!;
open LEN, "$Bin/../0829/hg19_refGeneMrna.fa.chrlist" or die $!;
while (<LEN>) {
	chomp;
	my @arr = split /\s+/;
	$len{$arr[0]} =$arr[1];
}
	
while (<VA>) {
	next if (/^#/);
	chomp;
	my $line = $_;
	my @row = split /\t/;
	if ($row[12] eq "exonic") {
		if ($row[-1] eq "UNKNOWN") {
			print TP "$line\t-\t-\t-\t-\n";
			next;
		}
		my %tp = ();
		my @arr = split ",", $row[-1];
		my @arr3 = ();
		foreach my $ele (@arr) {
			my @arr2 = split /:/, $ele;
			next if (@arr2 < 5);
			$tp{$arr2[1]} = $arr2[0] . "\t" . $arr2[1] . "\t" . $arr2[2] . "\t" . $arr2[3] . "\t" . $arr2[4];
			push @arr3, $arr2[1];			
		}
		next if (@arr3 == 0);
		my $long = &max(\@arr3);
		pop @row;
		$line = join "\t", @row;
		#print TP "@arr3\n";
		#print TP "$long\n";
		print TP "$line\t$tp{$long}\n";
	} elsif ($row[12] =~ m/splicing/i) {
		$row[-1] =~ m/(\w+\([^\)]*\))/;
		my $flag = $1;	
		if ($flag) {
			$flag = m/(\w+)\(([^\)]*)\)/;
			my $geneid = $1;
			my $str = $2;
			my %tp = ();
			my @arr = split ",", $str;
			my @arr3 = ();
			foreach my $ele (@arr) {
				my @arr2 = split /:/, $ele;
				next if (@arr2 < 3);
				$tp{$arr2[0]} = $arr2[0] . "\t" . $arr2[1] . "\t" . $arr2[2] . "\t" . "-";
				push @arr3, $arr2[0];
			}
			next if (@arr3 == 0);
			my $long = &max(\@arr3);
			pop @row;
			$line = join "\t", @row;
			print  TP "$line\t$geneid\t$tp{$long}\n";
		} else {
			print  TP "$line\t-\t-\t-\t-\n";
		}
	} else {
		print TP "$line\t-\t-\t-\t-\n";
	}
}
close VA;
close TP;
close LEN;
system("mv $ARGV[0].all_variant_function.tmp $ARGV[0].all_variant_function") == 0 or die $!;

sub max {
	my $ref = shift;
	my $length = 0;
	my $transcript = $ref->[0];
	foreach (@{$ref}) {
		if (exists $len{$_} && $len{$_} > $length) {
			$length = $len{$_};
			$transcript = $_;
		}
	}
	return $transcript;
}
