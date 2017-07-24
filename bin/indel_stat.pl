#!/usr/bin/perl
use Text::CSV;

if(@ARGV<2)
{die "perl $0 <indel_csv> <output_pre>\n";}
my $csvf=$ARGV[0];
my $out=$ARGV[1];

my %ins=();
my %del=();
my %ind=();
my $line=0;
my $csv = Text::CSV->new();
my $status;
my $csvoffset=0;
open IN,$csvf or die $!;
open OUT,">$out.xls" or die $!;
print OUT "InDel_length\tInDels\tInsertion\tDeletion\n";
while(<IN>)
{
	chomp;
	my $anno = $_;
	next if($anno =~ /^\s*$/);
	$status = $csv->parse($_);
	my @line=$csv->fields();
	if($line[0] eq 'Func')
	{
		if($line[15] ne 'Chr')
		{$csvoffset=-8;}
		next;
	}
	$line++;
	my $ref=$line[18+$csvoffset];
	my $alt=$line[19+$csvoffset];
	
	if($ref eq '-')
	{
		my $len=length($alt);
		$ins{$len}++;
		$ind{$len}++;
	}
	elsif($alt eq '-')
	{
		my $len=length($ref);
		$del{$len}++;
		$ind{$len}++;
	}
	else
	{
		my $len1=length($ref);
		my $len2=length($alt);
		if($len1 < $len2)
		{
			my $len=$len2-$len1;
			$ins{$len}++;
			$ind{$len}++;
		}
		else
		{
			my $len=$len1-$len2;
			$del{$len}++;
			$ind{$len}++;
		}
	}
}
close IN;
if($line==0)
{print OUT "1\t0\t0\t0\n";}
else
{
	foreach my $l (sort {$a<=>$b} keys %ind)
	{
		$del{$l}=0 unless(exists $del{$l});
		$ins{$l}=0 unless(exists $ins{$l});
		print OUT "$l\t$ind{$l}\t$ins{$l}\t$del{$l}\n";
	}
}
close OUT;

