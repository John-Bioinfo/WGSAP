#!/usr/bin/perl -w 
use strict;
open LL,"$ARGV[0].exonic_variant_function";
open L2,"$ARGV[0].variant_function";
open TT,">$ARGV[0].all_variant_function";

my %hash=();

while(<LL>){
	chomp;
	my @row=split /\t/,$_;
	$row[3]=~s/chr|Chr//;
	$hash{"$row[3]\t$row[4]\t$row[5]"}="$row[1]\t$row[2]";

}

while(<L2>){
        chomp;
        my @row=split /\t/,$_;
	$row[2]=~s/chr|Chr//;
	if($row[0] eq "exonic"){
		for(my $i=2;$i<@row;$i++){
			print TT "$row[$i]\t";
	
		}
		if(@row<12){
	                for(my $i=@row;$i<12;$i++){
        	                print TT "-\t";
	                }
		}

		#print "$row[2]\t$row[3]\t$row[4]\n";
		print TT "exonic\t".$hash{"$row[2]\t$row[3]\t$row[4]"}."\n";
		next;
	}
        my $temp1=shift @row;
	my $temp2=shift @row;
        foreach my $one(@row){
                print TT "$one\t";
        
        }
                if(@row<10){
                        for(my $i=@row;$i<10;$i++){
                                print TT "-\t";
                        }
                }

	print TT "$temp1\t-\t$temp2";
	
        print TT "\n";

}


