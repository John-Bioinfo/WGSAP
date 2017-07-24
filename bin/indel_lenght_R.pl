#!/usr/bin/perl -w
use strict;
use warnings;

my $usage=<<USAGE;
usage : perl $0 <SAMPLENAME> <ALL> <CDS> <OUTDIR>
USAGE

my($samplename,$allfile,$cdsfile,$outDir)=@ARGV;
die $usage unless $samplename && $allfile && $cdsfile && $outDir;

open  RSHELL,">$outDir/indel_length.R" or die $!;
print RSHELL "rt<-read.table(\"$allfile\",head=T,nrows=21)\n";
print RSHELL "png(\"$outDir/$samplename.indel_len.png\",width=800,heigh=500)\n";
print RSHELL "par(mar=c(5,5,5,5),mgp=c(3.5,1,0))\n";
print RSHELL "barplot(t(as.matrix(rt[,c(3,4,2)])),beside=T,names.arg=rt[,1],col=c(rgb(192,80,77,max=255),rgb(155,187,89,max=255),rgb(128,100,162,max=255)),ylim=c(0,max(rt[,2],rt[,3],rt[,4])*1.2),cex.lab=1.5,font.lab=2,cex.axis=1.5,cex.main=2,las=1,xlab=\"InDel length(bp)\",ylab=\"Number\",main=\"InDel length distribution (All)\")\n";
print RSHELL "legend(\"right\",c(\"Insertion\",\"Deletion\",\"Indels\"),lwd=3,lty=1,bty=\"n\",cex=1.5,col=c(rgb(192,80,77,max=255),rgb(155,187,89,max=255),rgb(128,100,162,max=255)))\n";
print RSHELL "dev.off()\n";
print RSHELL "\n";
print RSHELL "rt<-read.table(\"$cdsfile\",head=T,nrows=21)\n";
print RSHELL "png(\"$outDir/$samplename.indel_cds_len.png\",width=800,heigh=500)\n";
print RSHELL "par(mar=c(5,5,5,5),mgp=c(3.5,1,0))\n";
print RSHELL "barplot(t(as.matrix(rt[,c(3,4,2)])),beside=T,names.arg=rt[,1],col=c(rgb(192,80,77,max=255),rgb(155,187,89,max=255),rgb(128,100,162,max=255)),ylim=c(0,max(rt[,2],rt[,3],rt[,4])*1.2),cex.lab=1.5,font.lab=2,cex.axis=1.5,cex.main=2,las=1,xlab=\"InDel length(bp)\",ylab=\"Number\",main=\"InDel length distribution (CDS)\")\n";
print RSHELL "legend(\"right\",c(\"Insertion\",\"Deletion\",\"Indels\"),lwd=3,lty=1,bty=\"n\",cex=1.5,col=c(rgb(192,80,77,max=255),rgb(155,187,89,max=255),rgb(128,100,162,max=255)))\n";
print RSHELL "dev.off()\n";
close RSHELL;

system("/WORK/cheerland_1/YCC/bin/R-3.0.2/bin/Rscript $outDir/indel_length.R");
