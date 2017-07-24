#!/usr/bin/perl -w
use strict;
use File::Basename;
unless(@ARGV){
print "\n\tperl $0  <file1> <int>  <file2> > file2.out
	
	put file1's the <int> info into file2.
	file1 and file2  have the same format at the start 2 column;
	chr pos	other
	1	23234234	other
	1	23434344	other
	
	the position must be sorted by the site;

	eg.
	perl $0 file1 3 file2 >file2.out
	perl $0 file1 3:5 file2 >file2.out
	perl $0 file1 3:5:6 file2 >file2.out

	put the third column and the fifth column to the file2's end;	

";

exit;
}
my %hash=();
my $file1=$ARGV[0];
my $file2=$ARGV[2];
my @int=split /:/,$ARGV[1];
my $symbol="-";


open F1,"$file1" or die "$!";
open F2,"$file2";

my $position=0;
my $lastposition=0;
while(my $cds=<F2>){
	next if ($cds =~ m/^#/);
	chomp $cds;
	my @rowcds=split /\t/,$cds;
	
	my $gochr=$rowcds[0];
	if($gochr eq "X"){$gochr=23;}
	if($gochr eq "Y"){$gochr=24;}
	next if(length $gochr > 2 or $gochr =~ /M/i);

	my $gopos=$rowcds[1];
	my $gobase="$rowcds[3]$rowcds[4]";

	my $sum=0;my $mean=0;my $num=0;
	my $linenum=0;
	my $printopen=0;
	seek(F1,$position,0);
	while (my $line=<F1>){
		next if ($line =~ m/^#/);
		$linenum=1;
		chomp $line;
		my @row=split /\t/,$line;
		my  $thischr=$row[0];
		if($thischr eq "X"){$thischr=23;}
		if($thischr eq "Y"){$thischr=24;}
		if($thischr=~/\D/){next;}


		my $thispos=$row[1];
		my $thisbase="$row[3]$row[4]";

		if($thischr > $gochr){print "$cds"; foreach my $one(@int){print "\t$symbol";}print "\n";$printopen=1;last;}
		if($thischr < $gochr ){$position=tell(F1);next;}
		elsif($thischr==$gochr){

			if($thispos >$gopos){print "$cds";foreach my $one(@int){print "\t$symbol";}print "\n";$printopen=1;last;}
			if($thispos <$gopos){$position=tell(F1);next;}
		
			elsif($thispos==$gopos){
				if($thisbase ne $gobase){$position=tell(F1);next;}
				else{
				print "$cds";
				foreach my $one(@int){print "\t$row[$one-1]";}
				print "\n";
				$printopen=1;
				last;
				}
			}
		}
	}
	if($linenum==0){print "$cds"; foreach my $one(@int){print "\t$symbol";}print "\n";}
	elsif($printopen==0){print "$cds"; foreach my $one(@int){print "\t$symbol";}print "\n";}
}
