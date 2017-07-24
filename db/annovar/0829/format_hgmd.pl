#!/usr/bin/perl -w
use strict;

open LL,"$ARGV[0]";
while(<LL>){
	chomp ;
	my @row=split /\t/,$_;
	if($row[1]=~/>/ and ($row[1]=~/-/ or $row[1]=~/\+/)){
		print "$row[0]\t";
		print "$row[1]\t";
		if($row[2]=~/D|P/){print "$row[2]\n";}
		else{print "D?\n";}
	}
	elsif($row[1]=~/>/){
		print "$row[0]\t";
		if($row[1]=~/c\.(\d+)(\w)>(\w)/){
			print "c.$2$1$3\t";
			if($row[2]=~/D|P/i){
				print "$row[2]\n";
			}
			else{print "D?\n";}
		}


	}
	elsif($row[1]=~/(c\..*?del)/ or $row[1]=~/(c\..*?ins)/ or $row[1]=~/(c\..*?dup)/){
		print "$row[0]\t$1\t";
		if($row[2]=~/D|P/){print "$row[2]\n";}
		else{print "D?\n";}
	}
	elsif($row[1]=~/c\.\d/){
                print "$row[0]\t$row[1]\t";
                if($row[2]=~/D|P/){print "$row[2]\n";}
                else{print "D?\n";}
	}
}

