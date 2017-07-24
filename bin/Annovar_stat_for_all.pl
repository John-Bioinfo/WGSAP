#!/usr/bin/perl -w
use strict;
use lib qw(/WORK/cheerland_1/YCC/bin/lib/);
use Text::CSV;
use Getopt::Long;
use File::Basename;
my ($infile,$sample,$dir,$outfile,$thrd,$var,$help,$filter);
GetOptions
(
	"i=s"=>\$infile,
	"s=s"=>\$sample,
	"o=s"=>\$outfile,
	"t=f"=>\$thrd,
	"v=s"=>\$var,
	"filter"=>\$filter,
        "h"=>\$help,
);

my $usage=<<INFO;
Usage:
	perl $0 [options]
Options:

	-i <file>	:input file is the result of annotation by ANNOVAR,name after SampleID.genome_summary.csv 
	-s <string>	:the sample name 
	-o <string>	:the prefix of output file
	-t <float>	:the threshold of sift,default 0.05
	-filter		:the input file has been filted using snv_filter.R, default off
	-v <string>	:the type of Structural Variation 
				snp	SOAPsnp or samtools mpileup SNP
				indel	samtools mpileup InDel
				snv	SNVs were called by Varscan
				sv	SVs,use breakdancer
				cnv	CNVs,called by CNV detection 
	-h		:get the usage.
INFO


die $usage unless($infile && $var && $outfile);
die $usage if ($help);
my $name = basename $infile;
$name =~ /(.*)\.(genome|exome)_summary\.csv$/;
$sample ||=$1;
$outfile ||=$sample;
$thrd ||=0.05;
my $dbv;

my $csv = Text::CSV->new();
my $status;
my $csvoffset=0;

open IN,"$infile";
open OUT2,">$outfile.all_stat";
open OUT4,">$outfile.novel_stat" unless($var=~/sv|cnv/);
my($k_dbsnp132,$k1000,$rs,$novel,$hom,$het,$intergenic,$UTR,$UTR5,$intronic,$updown,$upstream,$exonic,$UTR3,$downstream,$ncRNA,$count,$exonicsplicing,$splicing,$nonsynonymous,$synonymous,$sift)=(0) x 22;
my($nhom,$nhet,$nintergenic,$nUTR,$nUTR5,$nintronic,$nupdown,$nupstream,$nexonic,$nUTR3,$ndownstream,$nncRNA,$ncount,$nexonicsplicing,$nsplicing,$nnonsynonymous,$nsynonymous,$nsift)=(0) x 22;
my ($del,$ins,$inv,$ctx,$itx,$ndel,$nins,$ninv,$nctx,$nitx)= (0) x 10;
my ($delr,$ampr,$ndelr,$nampr)= (0) x 4;
my ($stopg,$stopl,$nstopg,$nstopl)=(0) x 4;
my ($fsd,$fsi,$nfsd,$nfsi,$fss,$nfss,$nofsd,$nofsi,$nonfsd,$nonfsi,$nofss,$nonfss)= (0) x 12;
my ($ti,$tv,$dbti,$dbtv,$nti,$ntv)=(0) x 6;
#Func,Gene,ExonicFunc,AAChange,Conserved,SegDup,1000G_ALL,1000G_ALL,1000G_ALL,dbSNP132,SIFT,Chr,Start,End,Ref,Obs,Otherinfo
#Func,Gene,ExonicFunc,AAChange,Conserved,SegDup,1000G_ALL,1000G_ALL,1000G_ALL,dbSNP132,SIFT,PolyPhen2,LJB_PhyloP,LJB_MutationTaster,LJB_LRT,Chr,Start,End,Ref,Obs,Otherinfo
while(<IN>)
{
	chomp;
	my $anno = $_;
	next if($anno =~ /^\s*$/);
	$status = $csv->parse($_);
	my @line = $csv->fields();
	if($line[0] eq 'Func')
	{
		if($line[15] ne 'Chr')
		{$csvoffset=-8;}
		$dbv=$1 if($line[9]=~/dbSNP(\d+)/);
		next;
	}
	$count++;
	my ($k1,$k2,$k3,$db,$s)=@line[6,7,8,9,10];
	my $start=$line[16+$csvoffset];
	my $end=$line[17+$csvoffset];
	my $base1=$line[18+$csvoffset];
	my $base2=$line[19+$csvoffset];
	my $otherinfo=$line[20+$csvoffset];
	
	if ($var =~/snp|snv/)
	{
		if((($base1 eq 'A') && ($base2 eq 'G')) || (($base1 eq 'G') && ($base2 eq 'A')) || (($base1 eq 'C') && ($base2 eq 'T')) || (($base1 eq 'T') && ($base2 eq 'C')))
		{
			$ti++;
			$dbti++ if($db);
			if(defined $filter)
			{$nti++ if($k1 eq 'NA' && $k2 eq 'NA' && $k3 eq 'NA' && !$db);}
			else
			{$nti++ if(!($k1 || $k2 || $k3) && !$db);}
		}
		else
		{
			$tv++;
			$dbtv++ if($db);
			if(defined $filter)
			{$ntv++ if($k1 eq 'NA' && $k2 eq 'NA' && $k3 eq 'NA' && !$db);}
			else
			{$ntv++ if(!($k1 || $k2 || $k3) && !$db);}
		}
	}
	
    	if(($k1 || $k2 || $k3) && $db)
	{
		if(defined $filter)
		{$k_dbsnp132++ if($k1 ne 'NA' || $k2 ne 'NA' || $k3 ne 'NA');}
		else
		{$k_dbsnp132++;}
	}
	if(!$db && ($k1 || $k2 || $k3))
	{
		if(defined $filter)
		{$k1000++ if($k1 ne 'NA' || $k2 ne 'NA' || $k3 ne 'NA');}
		else
		{$k1000++;}
	}
	if((!($k1 || $k2 || $k3) || ($k1 eq 'NA' && $k2 eq 'NA' && $k3 eq 'NA')) && $db )
	{
		$rs++;
	}
	if((!($k1 || $k2 || $k3) || ($k1 eq 'NA' && $k2 eq 'NA' && $k3 eq 'NA')) && !$db)
	{
#novel
		$novel++;
		if($s =~ /\d/)
			{$nsift++ if($s < $thrd);}
#homozygosis and heterozygosis  "GT:PL:GQ","1/1:255,255,0:99"
		if($otherinfo=~/het/i)
			{$nhet++;}
		elsif($otherinfo=~/hom/i)
			{$nhom++;}
		else
			{
				if($anno=~/\"0\/1\:?/)
				{$nhet++;}
				elsif($anno=~/\"0\/0\:?/ || $anno=~/\"1\/1\:?/)
				{$nhom++;}
				else
				{$nhet++;}
			}
#exonicFunc
#synonymous and nonsynonymous
		if($line[2]=~/\bsynonymous\b/){$nsynonymous++;}
		if($line[2]=~/nonsynonymous\b/){$nnonsynonymous++;}
#stop gain and stop loss
		if ($line[2] =~ /\bstopgain\b/){$nstopg++;}
		if ($line[2] =~ /\bstoploss\b/){$nstopl++;}
#frameshift insertion/deletion/block substitution ,nonframeshift insertion/deletion/block substitution
		if ($line[2] =~ /\bframeshift\sdeletion\b/){$nofsd++;}
		if ($line[2] =~ /\bframeshift\sinsertion\b/){$nofsi++;}
		if ($line[2] =~ /\bnonframeshift\sdeletion\b/){$nonfsd++;}
		if ($line[2] =~ /\bnonframeshift\sinsertion\b/){$nonfsi++;}
		if ($line[2] =~ /\bframeshift\ssubstitution\b/){$nofss++;}
		if ($line[2] =~ /\bnonframeshift\ssubstitution\b/){$nonfss++;}
#fun
		if($line[0]=~/intergenic/){$nintergenic++;}
		elsif($line[0]=~/\bintronic/){$nintronic++;}
		elsif($line[0]=~/exonic\;splicing/){$nexonicsplicing++;}
		elsif($line[0]=~/\bexonic/){$nexonic++;}
		elsif($line[0]=~/\bsplicing/){$nsplicing++;}
		elsif($line[0]=~/UTR5\;UTR3/){$nUTR++;}
		elsif($line[0]=~/\bUTR5/){$nUTR5++;}
		elsif($line[0]=~/\bUTR3/){$nUTR3++;}
		elsif($line[0]=~/upstream\;downstream/){$nupdown++}
		elsif($line[0]=~/\bupstream/){$nupstream++;}
		elsif($line[0]=~/\bdownstream/){$ndownstream++;}
		elsif($line[0]=~/ncRNA/){$nncRNA++;}
		else{print $anno;}	
	}
#	else
#	{$novel++;}
#for dbsnp or novel
	if($s =~ /\d/)
		{$sift++ if($s <$thrd);}
#for shift
	if($otherinfo=~/het/i)
		{$het++;}
	elsif($otherinfo=~/hom/i)
		{$hom++;}
	else
		{
			if($anno=~/\"0\/1\:?/)
			{$het++;}
			elsif($anno=~/\"0\/0\:?/ || $anno=~/\"1\/1\:?/)
			{$hom++;}
			else
			{$het++;}
		}
#for hom or het
#for SV 
	if($anno=~/SVID=[^_]+_[^_]+_[^_]+_[^_]+_(\w+);/)
	{
		$del++ if($1 =~ /DEL/i);
		$ins++ if($1 =~ /INS/i);
		$inv++ if($1 =~ /INV/i);
		$ctx++ if($1 =~ /CTX/i);
		$itx++ if($1 =~ /ITX/i);
	}
#for CNV
	$delr+=$end-$start+1 if($anno=~/Type=deletion/i);
	$ampr+=$end-$start+1 if($anno=~/Type=amplification/i);
#exonicFunc
#synonymous and nonsynonymous
	if($line[2]=~/\bsynonymous\b/){$synonymous++;}
	if($line[2]=~/nonsynonymous\b/){$nonsynonymous++;}
#stop gain and stop loss
	if ($line[2] =~ /\bstopgain\b/){$stopg++;}
	if ($line[2] =~ /\bstoploss\b/){$stopl++;}
#frameshift insertion/deletion/block substitution ,nonframeshift insertion/deletion/block substitution
	if ($line[2] =~ /\bframeshift\sdeletion\b/){$fsd++;}
	if ($line[2] =~ /\bframeshift\sinsertion\b/){$fsi++;}
	if ($line[2] =~ /\bnonframeshift\sdeletion\b/){$nfsd++;}
	if ($line[2] =~ /\bnonframeshift\sinsertion\b/){$nfsi++;}
	if ($line[2] =~ /\bframeshift\ssubstitution\b/){$fss++;}
	if ($line[2] =~ /\bnonframeshift\ssubstitution\b/){$nfss++;}
#fun
	if($line[0]=~/intergenic/){$intergenic++;}
	elsif($line[0]=~/\bintronic/){$intronic++;}
	elsif($line[0]=~/exonic\;splicing/){$exonicsplicing++;}
	elsif($line[0]=~/\bexonic/){$exonic++;}
	elsif($line[0]=~/\bsplicing/){$splicing++;}
	elsif($line[0]=~/UTR5\;UTR3/){$UTR++;}
	elsif($line[0]=~/\bUTR5/){$UTR5++;}
	elsif($line[0]=~/\bUTR3/){$UTR3++;}
	elsif($line[0]=~/upstream\;downstream/){$updown++}
	elsif($line[0]=~/\bupstream/){$upstream++;}
	elsif($line[0]=~/\bdownstream/){$downstream++;}
	elsif($line[0]=~/ncRNA/){$ncRNA++;}
	else{print $anno;}
#for function
	}
close IN;
#$novel=$count-$k_dbsnp132-$k1000-$rs;
#print OUT "Sample\tcount\tk1000+dbsnp132\tk1000\tdbSNP\tnovel\thom\thet\tsynonymous\tnonsynonymous\tupstream\tdownstream\tUTR5\tUTR3\tncRNA\texonic;splicing\tsplicing\texonic\tintronic\tintergenic\tsift\n";
#print OUT "$sample\t$count\t$k_dbsnp132\t$k1000\t$rs\t$novel\t$hom\t$het\t$synonymous\t$nonsynonymous\t$upstream\t$downstream\t$UTR5\t$UTR3\t$ncRNA\t$exonicsplicing\t$splicing\t$exonic\t$intronic\t$intergenic\t$sift\n";
#print OUT "$sample\t$count\t$k_dbsnp132\t$k1000\t$rs\t$novel\t$hom\t$het\t$synonymous\t$nonsynonymous\t$exonic\t$exonicsplicing\t$splicing\t$ncRNA\t$UTR5\t$UTR3\t$intronic\t$upstream\t$downstream\t$intergenic\t$sift\n";
#print OUT3 "$sample\t$novel\t$nhom\t$nhet\t$nsynonymous\t$nnonsynonymous\t$nupstream\t$ndownstream\t$nUTR5\t$nUTR3\t$nncRNA\t$nexonicsplicing\t$nsplicing\t$nexonic\t$nintronic\t$nintergenic\t$nsift\n";
#print OUT3 "$sample\t$novel\t$nhom\t$nhet\t$nsynonymous\t$nnonsynonymous\t$nexonic\t$nexonicsplicing\t$nsplicing\t$nncRNA\t$nUTR5\t$nUTR3\t$nintronic\t$nupstream\t$ndownstream\t$nintergenic\t$nsift\n";
$tv=1 if($tv==0);
$dbtv=1 if($dbtv==0);
$ntv=1 if($ntv==0);
my $fre1=$ti/$tv;
my $fre2=$dbti/$dbtv;
my $fre3=$nti/$ntv;
#all
my $dbrate = 0;
if($count>0)
{
	$dbrate = ($k_dbsnp132+$rs)/$count*100;
}
print OUT2 "Sample\t$sample\n";
print OUT2 "Total\t$count\n";
if( $var =~ /sv/i ){
	print OUT2 "Insertion\t$ins\n";
	print OUT2 "Deletion\t$del\n";
	print OUT2 "Inversion\t$inv\n";
	print OUT2 "ITX\t$itx\n";
	print OUT2 "CTX\t$ctx\n";
}
unless( $var =~/sv|cnv/i){
	print OUT2 "1000genome and dbsnp$dbv\t$k_dbsnp132\n";
	print OUT2 "1000genome specific\t$k1000\n";
	print OUT2 "dbSNP$dbv specific\t$rs\n";
	printf OUT2 "dbSNP rate\t%4.2f%%\n",$dbrate;
	print OUT2 "Novel\t$novel\n";
	print OUT2 "Hom\t$hom\n";
	print OUT2 "Het\t$het\n";
	}
if( $var =~/snp|snv/i){
	print OUT2 "Synonymous\t$synonymous\n";
	print OUT2 "Missense\t$nonsynonymous\n";
	}
elsif( $var =~/indel/i){
	print OUT2 "Frameshift Insertion\t$fsi\n";
	print OUT2 "Non-frameshift Insertion\t$nfsi\n";
	print OUT2 "Frameshift Deletion\t$fsd\n";
	print OUT2 "Non-frameshift Deletion\t$nfsd\n";
	print OUT2 "Frameshift block substitution\t$fss\n";
	print OUT2 "Non-frameshift block substitution\t$nfss\n";
	}
unless ($var =~/sv|cnv/i){
	print OUT2 "Stopgain\t$stopg\n";
	print OUT2 "Stoploss\t$stopl\n";	
	}
print OUT2 "Exonic\t$exonic\n";
print OUT2 "Exonic and splicing\t$exonicsplicing\n";
print OUT2 "Splicing\t$splicing\n";
print OUT2 "NcRNA\t$ncRNA\n";
print OUT2 "UTR5\t$UTR5\n";
print OUT2 "UTR5 and UTR3\t$UTR\n";
print OUT2 "UTR3\t$UTR3\n";
print OUT2 "Intronic\t$intronic\n";
print OUT2 "Upstream\t$upstream\n";
print OUT2 "Upstream and downstream\t$updown\n";
print OUT2 "Downstream\t$downstream\n";
print OUT2 "Intergenic\t$intergenic\n";
print OUT2 "SIFT\t$sift\n" if( $var =~/snp|snv/);
if($var =~/snp|snv/i){
	printf OUT2 "Ti\/Tv\t%5.4f\n",$fre1;
	printf OUT2 "dbSNP Ti\/Tv\t%5.4f\n",$fre2;
	printf OUT2 "Novel Ti\/Tv\t%5.4f\n",$fre3;
	}
if( $var =~ /cnv/i)
{
	print OUT2 "Amplification Size\t$ampr\n";
	print OUT2 "Deletion Size\t$delr\n";
}
close OUT2;
#novel
unless($var =~/sv|cnv/){
	print OUT4 "Sample\t$sample\n";
	print OUT4 "Novel\t$novel\n";
	print OUT4 "Hom\t$nhom\n";
	print OUT4 "Het\t$nhet\n";
	if( $var =~/snp|snv/){
		print OUT4 "Synonymous\t$nsynonymous\n";
		print OUT4 "Missense\t$nnonsynonymous\n";
		}
	elsif($var =~/indel/){
		print OUT4 "Frameshift Insertion\t$nofsi\n";
		print OUT4 "Non-frameshift Insertion\t$nonfsi\n";
		print OUT4 "Frameshift Deletion\t$nofsd\n";
		print OUT4 "Non-frameshift Deletion\t$nonfsd\n";
		print OUT4 "Frameshift block substitution\t$nofss\n";
		print OUT4 "Non-frameshift block substitution\t$nonfss\n";
		}
	unless ($var =~/sv|cnv/){
		print OUT4 "Stopgain\t$nstopg\n";
		print OUT4 "Stoploss\t$nstopl\n";	
	}
	print OUT4 "Exonic\t$nexonic\n";
	print OUT4 "Exonic and splicing\t$nexonicsplicing\n";
	print OUT4 "Splicing\t$nsplicing\n";
	print OUT4 "NcRNA\t$nncRNA\n";
	print OUT4 "UTR5\t$nUTR5\n";
	print OUT4 "UTR5 and UTR3\t$nUTR\n";
	print OUT4 "UTR3\t$nUTR3\n";
	print OUT4 "Intronic\t$nintronic\n";
	print OUT4 "Upstream\t$nupstream\n";
	print OUT4 "Upstream and downstream\t$nupdown\n";
	print OUT4 "Downstream\t$ndownstream\n";
	print OUT4 "Intergenic\t$nintergenic\n";
	print OUT4 "SIFT\t$nsift\n" if( $var =~/snp|snv/);
	if($var =~/snp|snv/){
		printf OUT4 "Novel Ti\/Tv\t%5.4f\n",$fre3;
		}
}
close OUT4;
