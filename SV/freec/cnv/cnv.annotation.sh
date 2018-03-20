db=`ls -th /datapool/home/xuxiangyang/pipeline/exome/SV/freec/cnv/cnv.*.db | head -1`
file=$1
awk '{print $0"\t"$3-$2}' $file > $file.size
perl /datapool/home/xuxiangyang/pipeline/exome/SV/freec/cnv/cnv_N_ratio.pl --outDir ./ $file.size  > $file.size.N 
awk '{if($7 < 0.25) print}'  $file.size.N >  $file.size.N.filter
perl /datapool/home/xuxiangyang/pipeline/exome/SV/freec/cnv/cnv_freq_annotation.pl --cnvDB $db --outDir ./ $file.size.N > $file.size.N.freq
perl /datapool/home/xuxiangyang/pipeline/exome/SV/freec/cnv/cnv_gene_annotation.pl --outDir ./ $file.size.N.freq > $file.size.N.freq.gene
awk '{if($6 > 100000 && $7 < 0.25 && $8 < 2 && $10 != "-" && $4 < 5) print }' $file.size.N.freq.gene > $file.size.N.freq.gene.filter
