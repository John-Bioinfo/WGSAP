#!/usr/bin/perl -w 
use strict;
open LL,"$ARGV[0]";
while(<LL>){
	chomp;
	if($_=~/^#/){next;}
	my @row=split /\t/,$_;
	#    104 1       984971  rs111818381     G       A,C     .       .       RS=111818381;R
	$_=~/CLNSIG=(.*?);/;
	my $sig=$1;
	my $reflen=length($row[3]);
	my $alelen=length($row[4]);

	#print "$row[1]\t$row[2]\t$sig\n";
	if($row[4]=~/,/){
		my @tt=split /,/,$row[4];
		my @tempsig=split /,/,$sig;

		for(my $t=0;$t<@tt;$t++){
			#$t=~s/$row[3]//;
			my $sigre=$tempsig[$t];
			if(@tempsig-1<$t){$sigre=$tempsig[0];}
			my $tlen=length($tt[$t]);
			if($reflen>1 and $tlen==1 ){
                        	$row[3]=~s/^$tt[$t]//;
                        	$row[1]++;
                        	print "$row[0]\t$row[1]\t$row[1]\t$row[3]\t-\t$sigre\n";

	                }
        	        elsif($reflen==1 and $tlen>1 ){
                	        $tt[$t]=~s/^$row[3]//;
                        	print "$row[0]\t$row[1]\t$row[1]\t-\t$tt[$t]\t$sigre\n";
	                }
        	        else{
	
        	                print "$row[0]\t$row[1]\t$row[1]\t$row[3]\t$tt[$t]\t$sigre\n";
                	}
		}
	}
	else{
		if($reflen>1 and $alelen>1){
			print "$row[0]\t$row[1]\t$row[1]\t$row[3]\t$row[4]\t$sig\n";
		}
		elsif($reflen>1 and $alelen==1 ){
			$row[3]=~s/^$row[4]//;
			$row[1]++;
			print "$row[0]\t$row[1]\t$row[1]\t$row[3]\t-\t$sig\n";
		
		

		}
		elsif($reflen==1 and $alelen>1 ){
			$row[4]=~s/^$row[3]//;
			print "$row[0]\t$row[1]\t$row[1]\t-\t$row[4]\t$sig\n";
		}
		else{

			print "$row[0]\t$row[1]\t$row[1]\t$row[3]\t$row[4]\t$sig\n";
		}

	}



}
