#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Long;

my ($gatk,$out,$fre,$altd);

GetOptions
(
        "i=s"=>\$gatk,
        "f=f"=>\$fre,
        "d=i"=>\$altd,
        "o=s"=>\$out,
);

$fre ||= 0;
$altd ||= 4;

if(!$gatk || !$out)
{
        die "perl $0 -i GATK_vcf -f Min_alt_fre(%)[default 0] -d Min_alt_reads[default 4] -o output\n";
}

open OUT,">$out" or die $!;
open IN,$gatk or die $!;
while (<IN>)
{
        chomp;
        if($_ =~ /^#/)
        {
                print OUT "$_\n";
                next;
        }
        if($_ =~ /GT:AD:DP:GQ:PL[^:]+:([^:]+)/)
        {
                my ($d1,$d2)=(split /,/,$1)[0,1];
                my $pp=100*$d2/($d1+$d2);
                next if($d2 < $altd || $pp < $fre);
        }
        print OUT "$_\n";
}
close OUT;
close IN;
