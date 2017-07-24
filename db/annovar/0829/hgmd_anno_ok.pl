#!/usr/bin/perl -w 
use strict;

my %hash=();

open LL,"$ARGV[0]";
open L2,"$ARGV[1]";
while(<L2>){
	chomp;
	my @row=split /\t/,$_;
	$hash{"$row[0]\t$row[1]"}=$row[2];
}




while(<LL>){
	chomp ;
	my @row=split /\t/,$_;
	if($row[12]=~/\(/){
		my @tt=split /\(/,$row[12];
		my @name=split /;/,$tt[0];
		my @list=split /,/,$tt[1];
		my $open=0;my $start=0;
                foreach my $one(@list){
                        my @temp=split /:/,$one;
			if($one=~/exon/){
				$temp[2]=~s/\)$//;
				if($open==0 and exists($hash{"$name[0]\t$temp[2]"})){print "$_\t".$hash{"$name[0]\t$temp[2]"}."\n";$open++;}
			}
			$start=1;
                }
		if($open==0 and $start==1){print "$_\tNO\n";}

	}
	elsif($row[12]=~/:/){
		my @list=split /,/,$row[12];
		my $open=0;my $start=0;
		foreach my $one(@list){
			my @temp=split /:/,$one;
			if($open==0 and exists($hash{"$temp[0]\t$temp[3]"})){print "$_\t".$hash{"$temp[0]\t$temp[3]"}."\n";$open++;}
			$start=1;
		}
		if($open==0 and $start==1){print "$_\tNO\n";}

	}
	else{
		print "$_\tNO\n";

	}


}
