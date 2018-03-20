awk -v OFS='\t' '{print $3,$5,$6,$13,$12,$4}' hg19_refGene.txt > hg19_refGene.bed
