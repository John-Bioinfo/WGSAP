#!/usr/bin/env perl
use strict;
use warnings;
use Cwd 'abs_path';
use File::Basename;
use Getopt::Long;
use Data::Dumper;
use POSIX;


# Global variable
my $bin = "/datapool/home/xuxiangyang/pipeline/exome";
my $ref = "$bin/db/bwa/ucsc.hg19.fasta";
-e $ref || die $!;
my $step = "12345";
my $ft_para = "-n 0.1 -l 5 -q 0.5 -Q 2 -G -5 1"; # if add -i, it will be very slow
my $bwa_t = 8;
my $siteDB = `ls -t $bin/db/dbsnv/*.db | head -1`;
chomp $siteDB;
#print "$siteDB\n";
#exit;

#my $bwa_para = "-M -Y";
my $bwa_para = "-M";
my $tmpDir = `pwd`;
chomp $tmpDir;
my $workDir = $tmpDir;
my $t = 8;
my $at = "at2";
my $target_region;
my $interval_padding = 100;
my $DP = 10;

# Software path specified and check
my $tool = "$bin/tool";
my $soapnuke = "$tool/SOAPnuke";
-e $soapnuke || die $!;
my $bwa = "$tool/bwa";
-e $bwa || die $!;
my $samtools = "$tool/samtools";
-e $samtools || die $!;
my $picard = "$tool/picard.jar";
-e $picard || die $!;
my $gatk = "$tool/GenomeAnalysisTK.jar";
-e $gatk || die $!;
-e "$bin/bin/soapnuke_stat.pl" || die $!;
-e "$bin/bin/fqcheck" || die $!;
-e "$bin/bin/fqcheck_distribute.pl" || die $!;
my $annovarDir = "/datapool/home/xuxiangyang/pipeline/exome/db/annovar";
-e $annovarDir || die $!;

# Guide for pipeline
my $guide_separator = "#" x 80;
my $version = basename(abs_path($0));
$version =~ s/WGSAP_(\S+)\.pl/$1/;

my $guide=<<INFO;
VER

        AUTHOR: xuxiangyang(xy_xu\@foxmail.com)
        NAME: WholeGenomeSequencingAnalysisPipeline(WGSAP)
        VERSION: $version	2016-08-30

NOTE
	1. sample.lst format like as below:
	fq1	fq2	sampleId	lib	lane
	2. this pipeline include 5 steps:
	1) Data Filter
	2) Alignment
	3) Call SNP
	4) call InDel
	5) Annotation
	3. fq quality system should be phred 33
	4. you must set target region, bed file

        WGSAP [options] --project <project name> --target_region <target bed file> sample.lst

    	$guide_separator Basic $guide_separator
		-help <str>		print this guide information 
		-ref <str>		reference genome absolute path, default "$ref"
		-bin <str>		bin dir, default "$bin"
		-project <str>		project name
		-workDir <str>		work directory, default "$workDir"
		-step <str>		set step for run, default "$step"
		-target_region <str>		One or more genomic intervals over which to operate, it should be absolute path for bed file
		-interval_padding <i>		Amount of padding (in bp) to add to each interval, default $interval_padding
		-t <i>			set Number of data threads to allocate to this analysis, default $t
		-at <str>		specify the annotation method, default "$at"
		-dp <i>			variation filter according to read depth, default $DP
	$guide_separator Filter $guide_separator
		-ft_h <str>		print soapnuke filter help information
		-ft_para <str>		set the parameter for SOAPnuke filter, default "$ft_para"
	$guide_separator Alignment $guide_separator
		-ag_h <str>		print bwa mem help information
		-bwa_t <i>		number of threads for bwa mem, default $bwa_t
		-bwa_para <str>		set the parameter for bwa alignment, default "$bwa_para"
	$guide_separator SNP $guide_separator
	$guide_separator InDel $guide_separator
	$guide_separator Annotation $guide_separator
INFO

# Parameter get
my ($help, $project, $ft_h, $ag_h);
#my $target_region = "";
GetOptions(
	"h|help" => \$help,
	"ref=s" => \$ref,
	"bin=s" => \$bin,
	"project=s" => \$project,
	"workDir=s" => \$workDir,
	"step=s" => \$step,
	"target_region=s" => \$target_region,
	"interval_padding" => \$interval_padding,
	"t=i" => \$t,
	"at=s" => \$at,
	"dp=i" => \$DP,
	"ft_h" => \$ft_h,
	"ft_para=s" => \$ft_para,
	"ag_h" => \$ag_h,
	"bwa_t=i" => \$bwa_t,
	"bwa_para=s" => \$bwa_para,
);

# Call guide
die $guide if ((@ARGV != 1 || defined $help) && !defined $ft_h && !defined $ag_h);
die `$soapnuke filter` if (defined $ft_h);
die `$bwa mem` if (defined $ag_h);
die "Please set parameter --project!!\n" unless (defined $project);
#die "Please set parameter --target_region!!\n" unless (defined $target_region);

# Create directory
my $projectDir = "$workDir/$project";
system("mkdir -p $projectDir") == 0 || die $!;
my $java_tmp = "$workDir/java_tmp";
system("mkdir -p $java_tmp") == 0 || die $!;
my $ResultDir = "$workDir/Result";
system("mkdir -p $ResultDir") == 0 || die $!;

# Read input file
# fq1     fq2     sampleId        lib     lane 
my $sampleList = shift;
my %sampleInfo;
my $sample_total;
open SI, $sampleList or die $!;
while (<SI>) {
	next if (/^#/);
	chomp;
	$sample_total++;
	my @arr = split /\s+/;
	system("echo \"# Main Script\" > $projectDir/$arr[2].sh") == 0 || die $!;
	push @{$sampleInfo{$arr[2]}{$arr[3]}{$arr[4]}}, ($arr[0], $arr[1]);
	
}
close SI;
#print Dumper \%sampleInfo;

&sample_stat_log($sample_total);

# Step1 : Data Filter
if ($step =~ /1/) {
	foreach my $sampleId (keys %sampleInfo) {
		foreach my $lib (keys %{$sampleInfo{$sampleId}}) {
			foreach my $lane (keys %{$sampleInfo{$sampleId}{$lib}}) {
				my $laneDir = "$projectDir/$sampleId/$lib/$lane";
				system("mkdir -p $laneDir/CleanData") == 0 || die $!;
				my ($fq1, $fq2) = (${$sampleInfo{$sampleId}{$lib}{$lane}}[0], ${$sampleInfo{$sampleId}{$lib}{$lane}}[1]);
				open FT, ">$laneDir/CleanData/$sampleId.$lib.$lane.ft.sh" or die $!;
				print FT "# Step1 : Data Filter\n";
				print FT "echo \"Step1 : Data Filter Running!\"\n\n";
				print FT "$soapnuke filter -1 $fq1 -2 $fq2 $ft_para -o $laneDir/CleanData -C $laneDir/CleanData/$sampleId.$lib.$lane.1.clean.fq.gz -D $laneDir/CleanData/$sampleId.$lib.$lane.2.clean.fq.gz\n\n";
				print FT "$bin/bin/soapnuke_stat.pl $laneDir/CleanData/Basic_Statistics_of_Sequencing_Quality.txt $laneDir/CleanData/Statistics_of_Filtered_Reads.txt > $laneDir/CleanData/$sampleId.$lib.$lane.stat &\n\n";
				print FT "$bin/bin/fqcheck33 -r $laneDir/CleanData/$sampleId.$lib.$lane.1.clean.fq.gz -c $laneDir/CleanData/$sampleId.$lib.$lane.1.fqcheck &\n\n";
				print FT "$bin/bin/fqcheck33 -r $laneDir/CleanData/$sampleId.$lib.$lane.2.clean.fq.gz -c $laneDir/CleanData/$sampleId.$lib.$lane.2.fqcheck &\n\n";
				print FT "wait\n\n";
				print FT "# $bin/bin/fqcheck_distribute.pl $laneDir/CleanData/$sampleId.$lib.$lane.1.fqcheck $laneDir/CleanData/$sampleId.$lib.$lane.2.fqcheck -o $laneDir/CleanData/$sampleId.$lib.$lane.\n\n";
				print FT "# Finished Step1!\n";
				print FT "echo \"Finished Step1!\"\n";
				close FT;
				system("sh $bin/bin/Add_time_for_script.sh $laneDir/CleanData/$sampleId.$lib.$lane.ft.sh") == 0 || die $!;
				system("chmod 755 $laneDir/CleanData/$sampleId.$lib.$lane.ft.sh") == 0 || die $!;
				system("echo -e \"sh $laneDir/CleanData/$sampleId.$lib.$lane.ft.sh\\n\" >> $projectDir/$sampleId.sh") == 0 || die $!;
			}
		}
	}	
}
if ($step !~ /1/) {
	foreach my $sampleId (keys %sampleInfo) {
		foreach my $lib (keys %{$sampleInfo{$sampleId}}) {
			foreach my $lane (keys %{$sampleInfo{$sampleId}{$lib}}) {
				my $laneDir = "$projectDir/$sampleId/$lib/$lane";
				system("mkdir -p $laneDir/CleanData") == 0 || die $!;
				my ($fq1, $fq2) = (${$sampleInfo{$sampleId}{$lib}{$lane}}[0], ${$sampleInfo{$sampleId}{$lib}{$lane}}[1]);
				open FT, ">$laneDir/CleanData/$sampleId.$lib.$lane.ln.sh" or die $!;
				print FT "# Step1 : Link Clean Data!\n";
				print FT "echo \"Step1 :Link Clean Data!\"\n\n";
				print FT "ln -s $fq1 $laneDir/CleanData/$sampleId.$lib.$lane.1.clean.fq.gz\n\n";
				print FT "ln -s $fq2 $laneDir/CleanData/$sampleId.$lib.$lane.2.clean.fq.gz\n\n";
				print FT "# Finished Step1!\n";
				print FT "echo \"Finished Step1!\"\n";
				close FT;
				system("sh $bin/bin/Add_time_for_script.sh $laneDir/CleanData/$sampleId.$lib.$lane.ln.sh") == 0 || die $!;
				system("chmod 755 $laneDir/CleanData/$sampleId.$lib.$lane.ln.sh") == 0 || die $!;
				system("echo -e \"sh $laneDir/CleanData/$sampleId.$lib.$lane.ln.sh\\n\" >> $projectDir/$sampleId.sh") == 0 || die $!;
			}
		}
	}	
}


# Step2 : Alignment
if ($step =~ /2/) {
	foreach my $sampleId (keys %sampleInfo) {
		foreach my $lib (keys %{$sampleInfo{$sampleId}}) {
			my (@mul_lane, $libDir);
			$libDir = "$projectDir/$sampleId/$lib";
			system("mkdir -p $libDir") == 0 || die $!;
			foreach my $lane (keys %{$sampleInfo{$sampleId}{$lib}}) {
				my $laneDir = "$libDir/$lane";
				system("mkdir -p $laneDir/Alignment") == 0 || die $!;
				open AG, ">$laneDir/Alignment/$sampleId.$lib.$lane.ag.sh" or die $!;
				print AG "# Step2 : Alignment\n";
				print AG "echo \"Step2 : Alignment Running!\"\n";
				print AG "$bwa mem -t $bwa_t $bwa_para -R '\@RG\\tID:$lane\\tLB:$lib\\tSM:$sampleId\\tPL:ILLUMINA' $ref $laneDir/CleanData/$sampleId.$lib.$lane.1.clean.fq.gz $laneDir/CleanData/$sampleId.$lib.$lane.2.clean.fq.gz | $samtools view -S -b -@ $bwa_t - > $laneDir/Alignment/$sampleId.$lib.$lane.bam\n\n";
				#print AG "java -Xmx20g -jar $picard ReorderSam I=$laneDir/Alignment/$sampleId.$lib.$lane.bam O=$laneDir/Alignment/$sampleId.$lib.$lane.reorder.bam R=$ref\n\n";	
				print AG "java -Xmx20g -Djava.io.tmpdir=$java_tmp -jar $picard SortSam I=$laneDir/Alignment/$sampleId.$lib.$lane.bam O=$laneDir/Alignment/$sampleId.$lib.$lane.sort.bam SORT_ORDER=coordinate\n\n";	
				print AG "rm $laneDir/Alignment/$sampleId.$lib.$lane.bam\n\n";
				if ((keys %{$sampleInfo{$sampleId}{$lib}}) == 1) {
					print AG "ln -s $laneDir/Alignment/$sampleId.$lib.$lane.sort.bam $libDir/$sampleId.$lib.bam\n\n";
				} else {
					push @mul_lane, "I=$laneDir/Alignment/$sampleId.$lib.$lane.sort.bam"; 
				}			
				print AG "# Finished Alignment and Sort!\n";
				print AG "echo \"Finished Alignment and Sort!\"\n";
				close AG;
				system("sh $bin/bin/Add_time_for_script.sh $laneDir/Alignment/$sampleId.$lib.$lane.ag.sh") == 0 || die $!;
				system("chmod 755 $laneDir/Alignment/$sampleId.$lib.$lane.ag.sh") == 0 || die $!;
				system("echo -e \"sh $laneDir/Alignment/$sampleId.$lib.$lane.ag.sh\\n\" >> $projectDir/$sampleId.sh") == 0 || die $!;
			}
			open BM, ">$libDir/$sampleId.$lib.bm.sh" or die $!;
			print BM "# Step2 : Alignment\n";
			if ((keys %{$sampleInfo{$sampleId}{$lib}}) > 1) {
				my $input_bams = join " \\\n", @mul_lane;
				print BM "# Merge Sam\n";
				print BM "echo \"Merge Sam\"\n";
				print BM "java -Xmx20g -Djava.io.tmpdir=$java_tmp -jar $picard MergeSamFiles \\\n$input_bams \\\nO=$libDir/$sampleId.$lib.bam\n\n";
			}
			# Mark Duplicates Reads
			print BM "# Mark Duplicates Reads\n";
			print BM "echo \"Mark Duplicates Reads\"\n";
			print BM "java -Xmx15g -Djava.io.tmpdir=$java_tmp -jar $picard MarkDuplicates \\\nI=$libDir/$sampleId.$lib.bam \\\nO=$libDir/$sampleId.$lib.dup.bam \\\nMETRICS_FILE=$libDir/$sampleId.$lib.dup.metrics \\\nREMOVE_DUPLICATES=false\n\n";
			if (-e "$libDir/$sampleId.$lib.dup.bai") {
				 system("rm $libDir/$sampleId.$lib.dup.bai") == 0 || die $!;
			}
			print BM "rm -rf $libDir/*/Alignment/*.sort.bam $libDir/$sampleId.$lib.bam\n\n";
			print BM "java -Xmx20g -Djava.io.tmpdir=$java_tmp -jar $picard BuildBamIndex \\\nI=$libDir/$sampleId.$lib.dup.bam\n\n";
			# BAM stastics
			print BM "# BAM stastics\n";
			print BM "echo \"BAM stastics\"\n";
			# print BM "source /WORK/app/osenv/ln1/set2.sh\n\n" if (defined $target_region);
			print BM "perl $bin/bin/QC_exome.pl -i $libDir/$sampleId.$lib.dup.bam -r $target_region -o $libDir/QC -plot &\n\n" if (defined $target_region);
			# Local relignment
			print BM "# Local relignment\n";
			print BM "echo \"Local relignment\"\n";
			if (defined $target_region) {
				print BM "java -Xmx20g -Djava.io.tmpdir=$java_tmp -jar $gatk \\\n-T RealignerTargetCreator \\\n-nt $t \\\n-R $ref \\\n-I $libDir/$sampleId.$lib.dup.bam \\\n-o $libDir/$sampleId.$lib.dup.realign.intervals \\\n-known $bin/db/gatk/1000G_phase1.indels.hg19.sites.vcf \\\n-known $bin/db/gatk/Mills_and_1000G_gold_standard.indels.hg19.sites.vcf \\\n-L $target_region \\\n-ip $interval_padding\n\n";
			} else {
				print BM "java -Xmx20g -Djava.io.tmpdir=$java_tmp -jar $gatk \\\n-T RealignerTargetCreator \\\n-nt $t \\\n-R $ref \\\n-I $libDir/$sampleId.$lib.dup.bam \\\n-o $libDir/$sampleId.$lib.dup.realign.intervals \\\n-known $bin/db/gatk/1000G_phase1.indels.hg19.sites.vcf \\\n-known $bin/db/gatk/Mills_and_1000G_gold_standard.indels.hg19.sites.vcf\n\n";
			}
			print BM "java -Xmx20g -Djava.io.tmpdir=$java_tmp -jar $gatk \\\n-T IndelRealigner \\\n-R $ref \\\n-I $libDir/$sampleId.$lib.dup.bam \\\n-targetIntervals $libDir/$sampleId.$lib.dup.realign.intervals \\\n-o $libDir/$sampleId.$lib.dup.realign.bam \\\n-known $bin/db/gatk/1000G_phase1.indels.hg19.sites.vcf \\\n-known $bin/db/gatk/Mills_and_1000G_gold_standard.indels.hg19.sites.vcf\n\n";
			# print BM "wait\n\n";
			print BM "rm $libDir/$sampleId.$lib.dup.bam $libDir/$sampleId.$lib.dup.bai\n\n";
			# Base quality score recalibration
			print BM "# Base quality score recalibration\n";
			print BM "echo \"Base quality score recalibration\"\n";
			if (defined $target_region) {
				print BM "java -Xmx20g -Djava.io.tmpdir=$java_tmp -jar $gatk \\\n-T BaseRecalibrator \\\n-nct $t \\\n-R $ref \\\n-I $libDir/$sampleId.$lib.dup.realign.bam \\\n-knownSites $bin/db/gatk/dbsnp_138.hg19.vcf \\\n-knownSites $bin/db/gatk/Mills_and_1000G_gold_standard.indels.hg19.sites.vcf \\\n-knownSites $bin/db/gatk/1000G_phase1.indels.hg19.sites.vcf \\\n-o $libDir/$sampleId.$lib.dup.realign.grp \\\n-L $target_region \\\n-ip $interval_padding\n\n";
			} else {
				print BM "java -Xmx20g -Djava.io.tmpdir=$java_tmp -jar $gatk \\\n-T BaseRecalibrator \\\n-nct $t \\\n-R $ref \\\n-I $libDir/$sampleId.$lib.dup.realign.bam \\\n-knownSites $bin/db/gatk/dbsnp_138.hg19.vcf \\\n-knownSites $bin/db/gatk/Mills_and_1000G_gold_standard.indels.hg19.sites.vcf \\\n-knownSites $bin/db/gatk/1000G_phase1.indels.hg19.sites.vcf \\\n-o $libDir/$sampleId.$lib.dup.realign.grp\n\n";
			}
			print BM "java -Xmx20g -Djava.io.tmpdir=$java_tmp -jar $gatk \\\n-T PrintReads \\\n-nct $t \\\n-R $ref \\\n-I $libDir/$sampleId.$lib.dup.realign.bam \\\n-BQSR $libDir/$sampleId.$lib.dup.realign.grp \\\n-o $libDir/$sampleId.$lib.dup.realign.recal.bam\n\n";
			print BM "rm $libDir/$sampleId.$lib.dup.realign.bam $libDir/$sampleId.$lib.dup.realign.bai\n\n";
			close BM;
			system("sh $bin/bin/Add_time_for_script.sh $libDir/$sampleId.$lib.bm.sh") == 0 || die $!;
			system("chmod 755 $libDir/$sampleId.$lib.bm.sh") == 0 || die $!;
			system("echo -e \"sh $libDir/$sampleId.$lib.bm.sh\\n\" >> $projectDir/$sampleId.sh") == 0 || die $!;
		}
	}	
}

# Prepare Variant calling
if ($step =~ /3/ or $step =~ /4/) {
	foreach my $sampleId (keys %sampleInfo) {
		my $sampleDir = "$projectDir/$sampleId";
		foreach my $lib (keys %{$sampleInfo{$sampleId}}) {
			open VC, ">$sampleDir/$sampleId.vc.sh" or die $!;
			print VC "# Prepare Variant calling\n";
			print VC "echo \"Prepare Variant calling\"\n";
#			if (-e "$sampleDir/$sampleId.$lib.final.bam") {
#				system("rm $sampleDir/$sampleId.$lib.final.bam") == 0 || die $!;
#			}
			print VC "if [ -s \"$sampleDir/$sampleId.$lib.final.bam\" ]; then rm $sampleDir/$sampleId.$lib.final.bam; fi\n\n";
			print VC "ln -s $sampleDir/$lib/$sampleId.$lib.dup.realign.recal.bam $sampleDir/$sampleId.$lib.final.bam\n\n";
			print VC "$samtools index $sampleDir/$sampleId.$lib.final.bam\n\n";
			print VC "echo $sampleDir/$sampleId.$lib.final.bam >> $projectDir/bam.lst\n\n";
			if (defined $target_region) {
				print VC "java -Xmx20g -Djava.io.tmpdir=$java_tmp -jar $gatk \\\n-T HaplotypeCaller \\\n-nct $t \\\n-R $ref \\\n-I $sampleDir/$sampleId.$lib.final.bam \\\n--dbsnp $bin/db/gatk/dbsnp_138.hg19.vcf \\\n--genotyping_mode DISCOVERY \\\n-stand_emit_conf 10 \\\n-stand_call_conf 50 \\\n-o $sampleDir/$sampleId.variants.vcf \\\n-L $target_region \\\n-ip $interval_padding\n\n";
			} else {
				print VC "java -Xmx20g -Djava.io.tmpdir=$java_tmp -jar $gatk \\\n-T HaplotypeCaller \\\n-nct $t \\\n-R $ref \\\n-I $sampleDir/$sampleId.$lib.final.bam \\\n--dbsnp $bin/db/gatk/dbsnp_138.hg19.vcf \\\n--genotyping_mode DISCOVERY \\\n-stand_emit_conf 10 \\\n-stand_call_conf 50 \\\n-o $sampleDir/$sampleId.variants.vcf\n\n";
			}
			print VC "# Finished prepare!\n";
			print VC "echo \"Finished prepare!\"\n";
			close VC;
			system("sh $bin/bin/Add_time_for_script.sh $sampleDir/$sampleId.vc.sh") == 0 || die $!;
			system("chmod 755 $sampleDir/$sampleId.vc.sh") == 0 || die $!;
			system("echo -e \"sh $sampleDir/$sampleId.vc.sh\\n\" >> $projectDir/$sampleId.sh") == 0 || die $!;
		}
	}
}

my $variant_head = "#CHROM\\tStart\\tEnd\\tREF\\tALT\\tHH\\tRef_dp\\tAlt_dp\\tQUAL\\tDP\\tMQ\\tQD\\tEx\\tSy\\tGene\\tNM\\tExon\\tNAC\\tAAC\\tDbsnp\\tClinvar\\t1000G_ALL\\t1000G_EAS\\t1000G_EUR\\tExAC_ALL\\tExAC_EAS\\tSIFT_pred\\tPolyphen2_HDIV_pred\\tPolyphen2_HVAR_pred\\tLRT_pred\\tMutationTaster_pred\\tMutationAssessor_pred\\tFATHMM_pred\\tRadialSVM_pred\\tLR_preVEST3_score\\tPred_score\\tVariant_freq\\tSample_Number\\tHgmd\\tPhenotype";

# Step3 : SNP
if ($step =~ /3/) {
	foreach my $sampleId (keys %sampleInfo) {
		my $snpDir = "$projectDir/$sampleId/SNP";
                system("mkdir -p $snpDir") == 0 || die $!;
		open SNP, ">$snpDir/$sampleId.snp.sh" or die $!;
		print SNP "# Extract and Filter SNPs\n";
		print SNP "echo \"Extract and Filter SNPs\"\n";
		print SNP "java -jar $gatk \\\n-T SelectVariants \\\n-nt $t \\\n-R $ref \\\n-V $projectDir/$sampleId/$sampleId.variants.vcf \\\n-selectType SNP \\\n-o $snpDir/$sampleId.snps.vcf\n\n";
		print SNP "java -jar $gatk \\\n-T VariantFiltration \\\n-R $ref \\\n-V $snpDir/$sampleId.snps.vcf \\\n--filterExpression \"QD < 2.0 || FS > 60.0 || MQ < 40.0 || SOR > 3.0 || DP < $DP\" \\\n--filterName \"SNP_filter\" \\\n-cluster 2 \\\n-window 5 \\\n-o $snpDir/$sampleId.snps.mark.vcf\n\n";
		print SNP "grep -e \"#\" -e \"PASS\" $snpDir/$sampleId.snps.mark.vcf > $snpDir/$sampleId.snps.filter.vcf\n\n";
		print SNP "# Finished Extract and Filter SNPs!\n";
		print SNP "echo \"Finished Extract and Filter SNPs!\"\n";
		close SNP;
		system("sh $bin/bin/Add_time_for_script.sh $snpDir/$sampleId.snp.sh") == 0 || die $!;
		system("chmod 755 $snpDir/$sampleId.snp.sh") == 0 || die $!;
		#system("echo -e \"sh $snpDir/$sampleId.snp.sh\\n\" >> $projectDir/$sampleId.sh") == 0 || die $!;
		if ($step =~ /5/ && $at eq "at1") {
			open SA, ">$snpDir/$sampleId.snp.annovar.sh" or die $!;
			print SA "# SNP Annotation\n";
			print SA "echo \"SNP Annotation\"\n";
			print SA "perl $annovarDir/convert2annovar.pl -format vcf4 --includeinfo -filter pass $snpDir/$sampleId.snps.filter.vcf > $snpDir/$sampleId.snps.filter.annovar\n\n";
			print SA "perl $annovarDir/summarize_annovar.pl  --buildver hg19 --verdbsnp 137 --remove $snpDir/$sampleId.snps.filter.annovar $annovarDir\n\n";
			print SA "perl $bin/bin/Annovar_stat_for_all.pl -i $snpDir/$sampleId.snps.filter.annovar.genome_summary.csv -o $snpDir/$sampleId.snps.filter.annovar -s $sampleId -v snp\n\n";
			print SA "# Finished SNP Annotation!\n";
			print SA "echo \"Finished SNP Annotation!\"\n";
			close SA;
	                system("sh $bin/bin/Add_time_for_script.sh $snpDir/$sampleId.snp.annovar.sh") == 0 || die $!;
        	        system("chmod 755 $snpDir/$sampleId.snp.annovar.sh") == 0 || die $!;
			system("echo -e \"sh $snpDir/$sampleId.snp.sh && sh $snpDir/$sampleId.snp.annovar.sh &\\n\" >> $projectDir/$sampleId.sh") == 0 || die $!;
		}
		if ($step =~ /5/ && $at eq "at2") {
			open SA, ">$snpDir/$sampleId.snp.annovar.sh" or die $!;
                        print SA "# SNP Annotation\n";
                        print SA "echo \"SNP Annotation\"\n";
			print SA "perl $annovarDir/bin/convert2annovar_ycc.pl -format vcf4 -filter pass $snpDir/$sampleId.snps.filter.vcf > $snpDir/$sampleId.snps.filter.annovar\n\n";	
			print SA "perl $annovarDir/bin/annotate_variation.pl -geneanno -buildver hg19 -outfile $snpDir/$sampleId.snps -exonsort $snpDir/$sampleId.snps.filter.annovar $annovarDir/0829\n\n";	
			print SA "perl $annovarDir/bin/merge_variant_funtion.pl $snpDir/$sampleId.snps\n\n";	
			print SA "perl $annovarDir/bin/add_file1_info_to_file2.pl $annovarDir/0829/hg19_snp137_sort.txt 6 $snpDir/$sampleId.snps.all_variant_function > $snpDir/$sampleId.snps.all_variant_function.dbsnp\n\n";	
			print SA "perl $annovarDir/bin/add_file1_info_to_file2.pl $annovarDir/0829/yang_OK/hg19_clinvar_20160802_simple.txt 6 $snpDir/$sampleId.snps.all_variant_function.dbsnp > $snpDir/$sampleId.snps.all_variant_function.dbsnp.clinvar\n\n";	
			print SA "perl $annovarDir/bin/add_file1_info_to_file2.pl $annovarDir/0829/hg19_popfreq_all_20150413.txt 7:10:11:13:16 $snpDir/$sampleId.snps.all_variant_function.dbsnp.clinvar > $snpDir/$sampleId.snps.all_variant_function.dbsnp.clinvar.freq\n\n";	
			print SA "perl $annovarDir/bin/add_file1_info_to_file2.pl $annovarDir/0829/hg19_ljb26_all.txt 7:9:11:13:15:17:19:21:23 $snpDir/$sampleId.snps.all_variant_function.dbsnp.clinvar.freq > $snpDir/$sampleId.snps.all_variant_function.dbsnp.clinvar.freq.pred\n\n";	
			#print SA "perl $annovarDir/bin/hgmd_anno_ok.pl $snpDir/$sampleId.snps.all_variant_function.dbsnp.clinvar.freq.pred $annovarDir/0829/hg19_HGMD.simple.re.txt > $snpDir/$sampleId.snps.annotation.final.xls\n\n";	
			print SA "perl $annovarDir/bin/pred_score.pl $snpDir/$sampleId.snps.all_variant_function.dbsnp.clinvar.freq.pred > $snpDir/$sampleId.snps.all_variant_function.dbsnp.clinvar.freq.pred.score\n\n";
			print SA "perl $annovarDir/bin/add_file1_info_to_file2.pl $siteDB 6:8 $snpDir/$sampleId.snps.all_variant_function.dbsnp.clinvar.freq.pred.score > $snpDir/$sampleId.snps.all_variant_function.dbsnp.clinvar.freq.pred.score.children\n\n";
			print SA "perl $annovarDir/bin/add_file1_info_to_file2.pl $bin/db/hgmd/hgmd_hg19.txt 6 $snpDir/$sampleId.snps.all_variant_function.dbsnp.clinvar.freq.pred.score.children > $snpDir/$sampleId.snps.all_variant_function.dbsnp.clinvar.freq.pred.score.children.hgmd\n\n";
			print SA "perl $annovarDir/bin/phenotype.pl $snpDir/$sampleId.snps.all_variant_function.dbsnp.clinvar.freq.pred.score.children.hgmd  $annovarDir/0829/gene_phenotype.md > $snpDir/$sampleId.snps.all_variant_function.dbsnp.clinvar.freq.pred.score.children.hgmd.phenotype\n\n";
			print SA "sed -i '1i $variant_head' $snpDir/$sampleId.snps.all_variant_function.dbsnp.clinvar.freq.pred.score.children.hgmd.phenotype\n\n";
			print SA "if [ -s \"$snpDir/$sampleId.snps.annotation.final.xls\" ]; then rm $snpDir/$sampleId.snps.annotation.final.xls; fi\n\n";
			print SA "ln -s $snpDir/$sampleId.snps.all_variant_function.dbsnp.clinvar.freq.pred.score.children.hgmd.phenotype $snpDir/$sampleId.snps.annotation.final.xls\n\n";
			#print SA "sed -i '1i $variant_head' $snpDir/$sampleId.snps.annotation.final.xls\n\n";	
			print SA "# Finished SNP Annotation!\n";
			print SA "echo \"Finished SNP Annotation!\"\n";
			close SA;
	                system("sh $bin/bin/Add_time_for_script.sh $snpDir/$sampleId.snp.annovar.sh") == 0 || die $!;
        	        system("chmod 755 $snpDir/$sampleId.snp.annovar.sh") == 0 || die $!;
			system("echo -e \"sh $snpDir/$sampleId.snp.sh && sh $snpDir/$sampleId.snp.annovar.sh &\\n\" >> $projectDir/$sampleId.sh") == 0 || die $!;
		}
	}
}

# Step4 : InDel
if ($step =~ /4/) {
	 foreach my $sampleId (keys %sampleInfo) {
                my $indelDir = "$projectDir/$sampleId/InDel";
                system("mkdir -p $indelDir") == 0 || die $!;
                open INDEL, ">$indelDir/$sampleId.indel.sh" or die $!;
                print INDEL "# Extract and Filter InDels\n";
                print INDEL "echo \"Extract and Filter InDels\"\n";
		print INDEL "java -jar $gatk \\\n-T SelectVariants \\\n-nt $t \\\n-R $ref \\\n-V $projectDir/$sampleId/$sampleId.variants.vcf \\\n-selectType INDEL \\\n-o $indelDir/$sampleId.indels.vcf\n\n";
		print INDEL "java -jar $gatk \\\n-T VariantFiltration \\\n-R $ref \\\n-V $indelDir/$sampleId.indels.vcf \\\n--filterExpression \"QD < 2.0 || FS > 200.0 || SOR > 10.0 || DP < $DP\" \\\n--filterName \"INDEL_filter\" \\\n-o $indelDir/$sampleId.indels.mark.vcf\n\n";
		print INDEL "grep -e \"#\" -e \"PASS\" $indelDir/$sampleId.indels.mark.vcf > $indelDir/$sampleId.indels.filter.vcf\n\n";
                print INDEL "# Finishled Extract and Filter InDels!\n";
                print INDEL "echo \"Finished Extract and Filter InDels!\"\n";
                close INDEL;
                system("sh $bin/bin/Add_time_for_script.sh $indelDir/$sampleId.indel.sh") == 0 || die $!;
                system("chmod 755 $indelDir/$sampleId.indel.sh") == 0 || die $!;
		#system("echo -e \"sh $indelDir/$sampleId.indel.sh\\n\" >> $projectDir/$sampleId.sh") == 0 || die $!;
		if ($step =~ /5/ && $at eq "at1") {
			open IA, ">$indelDir/$sampleId.indel.annovar.sh" or die $!;
			print IA "# InDel Annotation\n";
			print IA "echo \"InDel Annotation\"\n";
			print IA "perl $annovarDir/convert2annovar.pl -format vcf4 --includeinfo -filter pass $indelDir/$sampleId.indels.filter.vcf > $indelDir/$sampleId.indels.filter.annovar\n\n";
			print IA "perl $annovarDir/summarize_annovar.pl  --buildver hg19 --verdbsnp 137 --remove $indelDir/$sampleId.indels.filter.annovar $annovarDir\n\n";
			print IA "perl $bin/bin/Annovar_stat_for_all.pl -i $indelDir/$sampleId.indels.filter.annovar.genome_summary.csv -o $indelDir/$sampleId.indels.filter.annovar -s $sampleId -v indel\n\n";
			print IA "perl $bin/bin/indel_stat.pl $indelDir/$sampleId.indels.filter.annovar.genome_summary.csv $indelDir/$sampleId.indels.filter.annovar.len\n\n";
			print IA "perl $bin/bin/indel_stat.pl $indelDir/$sampleId.indels.filter.annovar.exome_summary.csv $indelDir/$sampleId.indels.filter.annovar.CDS.len\n\n";
			print IA "perl $bin/bin/indel_lenght_R.pl $sampleId $indelDir/$sampleId.indels.filter.annovar.len.xls $indelDir/$sampleId.indels.filter.annovar.CDS.len.xls $indelDir\n\n";
			print IA "# Finished InDel Annotation!\n";
                        print IA "echo \"Finished InDel Annotation!\"\n";
			close IA;
			system("sh $bin/bin/Add_time_for_script.sh $indelDir/$sampleId.indel.annovar.sh") == 0 || die $!;
                        system("chmod 755 $indelDir/$sampleId.indel.annovar.sh") == 0 || die $!;
			system("echo -e \"sh $indelDir/$sampleId.indel.sh && sh $indelDir/$sampleId.indel.annovar.sh &\\n\" >> $projectDir/$sampleId.sh") == 0 || die $!;
                }
		if ($step =~ /5/ && $at eq "at2") {
			open IA, ">$indelDir/$sampleId.indel.annovar.sh" or die $!;
                        print IA "# InDel Annotation\n";
                        print IA "echo \"InDel Annotation\"\n";
			print IA "perl $annovarDir/bin/convert2annovar_ycc.pl -format vcf4 -filter pass $indelDir/$sampleId.indels.filter.vcf > $indelDir/$sampleId.indels.filter.annovar\n\n";	
			print IA "perl $annovarDir/bin/annotate_variation.pl -geneanno -buildver hg19 -outfile $indelDir/$sampleId.indels -exonsort $indelDir/$sampleId.indels.filter.annovar $annovarDir/0829\n\n";	
			print IA "perl $annovarDir/bin/merge_variant_funtion.pl $indelDir/$sampleId.indels\n\n";	
			print IA "perl $annovarDir/bin/add_file1_info_to_file2.pl $annovarDir/0829/hg19_snp137_sort.txt 6 $indelDir/$sampleId.indels.all_variant_function > $indelDir/$sampleId.indels.all_variant_function.dbsnp\n\n";	
			print IA "perl $annovarDir/bin/add_file1_info_to_file2.pl $annovarDir/0829/yang_OK/hg19_clinvar_20160802_simple.txt 6 $indelDir/$sampleId.indels.all_variant_function.dbsnp > $indelDir/$sampleId.indels.all_variant_function.dbsnp.clinvar\n\n";	
			print IA "perl $annovarDir/bin/add_file1_info_to_file2.pl $annovarDir/0829/hg19_popfreq_all_20150413.txt 7:10:11:13:16 $indelDir/$sampleId.indels.all_variant_function.dbsnp.clinvar > $indelDir/$sampleId.indels.all_variant_function.dbsnp.clinvar.freq\n\n";	
			print IA "perl $annovarDir/bin/add_file1_info_to_file2.pl $annovarDir/0829/hg19_ljb26_all.txt 7:9:11:13:15:17:19:21:23 $indelDir/$sampleId.indels.all_variant_function.dbsnp.clinvar.freq > $indelDir/$sampleId.indels.all_variant_function.dbsnp.clinvar.freq.pred\n\n";	
			#print IA "perl $annovarDir/bin/hgmd_anno_ok.pl $indelDir/$sampleId.indels.all_variant_function.dbsnp.clinvar.freq.pred $annovarDir/0829/hg19_HGMD.simple.re.txt > $indelDir/$sampleId.indels.annotation.final.xls\n\n";	
			print IA "perl $annovarDir/bin/pred_score.pl $indelDir/$sampleId.indels.all_variant_function.dbsnp.clinvar.freq.pred > $indelDir/$sampleId.indels.all_variant_function.dbsnp.clinvar.freq.pred.score\n\n";
			print IA "perl $annovarDir/bin/add_file1_info_to_file2.pl $siteDB 6:8 $indelDir/$sampleId.indels.all_variant_function.dbsnp.clinvar.freq.pred.score > $indelDir/$sampleId.indels.all_variant_function.dbsnp.clinvar.freq.pred.score.children\n\n";
			print IA "perl $annovarDir/bin/add_file1_info_to_file2.pl $bin/db/hgmd/hgmd_hg19.txt 6 $indelDir/$sampleId.indels.all_variant_function.dbsnp.clinvar.freq.pred.score.children > $indelDir/$sampleId.indels.all_variant_function.dbsnp.clinvar.freq.pred.score.children.hgmd\n\n";
			print IA "perl $annovarDir/bin/phenotype.pl $indelDir/$sampleId.indels.all_variant_function.dbsnp.clinvar.freq.pred.score.children.hgmd  $annovarDir/0829/gene_phenotype.md > $indelDir/$sampleId.indels.all_variant_function.dbsnp.clinvar.freq.pred.score.children.hgmd.phenotype\n\n";
			print IA "sed -i '1i $variant_head' $indelDir/$sampleId.indels.all_variant_function.dbsnp.clinvar.freq.pred.score.children.hgmd.phenotype\n\n";
			print IA "if [ -s \"$indelDir/$sampleId.indels.annotation.final.xls\" ]; then rm $indelDir/$sampleId.indels.annotation.final.xls; fi\n\n";
			print IA "ln -s $indelDir/$sampleId.indels.all_variant_function.dbsnp.clinvar.freq.pred.score.children.hgmd.phenotype $indelDir/$sampleId.indels.annotation.final.xls\n\n";
			#print IA "sed -i '1i $variant_head' $indelDir/$sampleId.indels.annotation.final.xls\n\n";	
			print IA "# Finished InDel Annotation!\n";
                        print IA "echo \"Finished InDel Annotation!\"\n";
                        close IA;
                        system("sh $bin/bin/Add_time_for_script.sh $indelDir/$sampleId.indel.annovar.sh") == 0 || die $!;
                        system("chmod 755 $indelDir/$sampleId.indel.annovar.sh") == 0 || die $!;
                        system("echo -e \"sh $indelDir/$sampleId.indel.sh && sh $indelDir/$sampleId.indel.annovar.sh &\\n\" >> $projectDir/$sampleId.sh") == 0 || die $!;
			system("echo -e \"wait\\n\" >> $projectDir/$sampleId.sh") == 0 || die $!;
                }
        }
}

if ($step =~ /3/ && $step =~ /4/) {
	foreach my $sampleId (keys %sampleInfo) {
		open CAT, ">$projectDir/$sampleId/cat.variants.sh" or die $!;
		print CAT "cat $projectDir/$sampleId/SNP/$sampleId.snps.annotation.final.xls $projectDir/$sampleId/InDel/$sampleId.indels.annotation.final.xls | grep -vE '^#' > $projectDir/$sampleId/$sampleId.variants.annotation.xls\n\n";
		print CAT "sed -i '1i $variant_head' $projectDir/$sampleId/$sampleId.variants.annotation.xls\n\n";
		print CAT "iconv -f UTF-8 -t GB18030 $projectDir/$sampleId/$sampleId.variants.annotation.xls > $projectDir/$sampleId/$sampleId.variants.annotation.ch.xls\n\n";
		print CAT "cp $projectDir/$sampleId/$sampleId.variants.*.xls $ResultDir/\n\n";
		print CAT "#rm -rf $java_tmp\n\n";
		close CAT;
		system("sh $bin/bin/Add_time_for_script.sh $projectDir/$sampleId/cat.variants.sh") == 0 || die $!;
		system("echo -e \"sh $projectDir/$sampleId/cat.variants.sh\\n\" >> $projectDir/$sampleId.sh") == 0 || die $!;
	}	
}

system("ls $projectDir/*.sh | while read i; do sh $bin/bin/Add_time_for_script.sh \$i; done") == 0 || die $!;
system("chmod 755 $projectDir/*.sh") == 0 || die $!;
system("ls $projectDir/*.sh > $projectDir/script.lst") == 0 || die $!;

sub sample_stat_log {
        my $total = shift;
        my $time = strftime("%Y%m%d",localtime());
	system("mkdir -p $bin/count_log") == 0 or die $!;
        open LOG, ">>$bin/count_log/sample_stat.log" or die $!;
        print LOG "$time\t$total\n";
        close LOG;
}
