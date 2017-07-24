#!/bin/bash
if  [ $# -lt 1 ]
then
	echo "neet 1 input file"
fi


name=$1
yang=`echo $name|cut -d "." -f1`

perl /WORK/cheerland_1/YCC/bin/database/annovar/0829/convert2annovar_ycc.pl -format vcf4 $1  >$yang.snp.vcf.annotype
perl /WORK/cheerland_1/YCC/bin/database/annovar/0829//annotate_variation.pl -geneanno -buildver hg19 -outfile $yang -exonsort $yang.snp.vcf.annotype   /WORK/cheerland_1/YCC/bin/database/annovar/0829/
perl /WORK/cheerland_1/YCC/bin/database/annovar/0829/merge_variant_funtion.pl $yang
perl  /WORK/cheerland_1/YCC/bin/database/annovar/0829/add_file1_info_to_file2.pl /WORK/cheerland_1/YCC/bin/database/annovar/0829/hg19_snp137_sort.txt  6 $yang.all_variant_function>$yang.all_variant_function.dbsnp
perl  /WORK/cheerland_1/YCC/bin/database/annovar/0829/add_file1_info_to_file2.pl /WORK/cheerland_1/YCC/bin/database/annovar/0829/yang_OK/hg19_clinvar_20160802_simple.txt 6 $yang.all_variant_function.dbsnp>$yang.all_variant_function.clinvar
perl /WORK/cheerland_1/YCC/bin/database/annovar/0829/add_file1_info_to_file2.pl  /WORK/cheerland_1/YCC/bin/database/annovar/0829/hg19_popfreq_all_20150413.txt  7:10:11:13:16 $yang.all_variant_function.clinvar >$yang.all_variant_function.clinvar.freq 
perl /WORK/cheerland_1/YCC/bin/database/annovar/0829/add_file1_info_to_file2.pl /WORK/cheerland_1/YCC/bin/database/annovar/0829/hg19_ljb26_all.txt 7:9:11:13:15:17:19:21:23 $yang.all_variant_function.clinvar.freq >$yang.all_variant_function.clinvar.freq.pred
perl  /WORK/cheerland_1/YCC/bin/database/annovar/0829/hgmd_anno_ok.pl  $yang.all_variant_function.clinvar.freq.pred /WORK/cheerland_1/YCC/bin/database/annovar/0829/hg19_HGMD.simple.re.txt >$yang.all_variant_function.clinvar.freq.pred.hgmd.xls
