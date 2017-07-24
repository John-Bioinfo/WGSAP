#!/HOME/cheerland_1/WORKSPACE/soft/R-3.3.1/bin/R
Args <- commandArgs()
#print(Args[6])
#q()

gt_time <- paste('CODEX', format(Sys.time(), '%Y%m%d'), sep = '_')

# Get directories of .bam files, read in exon target positions from .bed files, and get sample names.
library(CODEX)
chr <- Args[6]
inputDir <- Args[7]
outDir <- Args[8]
sampleList <- Args[9]
projectname = Args[10]
#lf <- Args[11]
bamFile <- list.files(file.path(inputDir, chr), pattern = '*.bam$')
bamdir <- file.path(file.path(inputDir, chr), bamFile)
sampname <- as.matrix(read.table(sampleList))
bedFile <- file.path("/HOME/cheerland_1/WORKSPACE/pipeline/exome/db/exome", "agilent_region.B37.bed")
bambedObj <- getbambed(bamdir = bamdir, bedFile = bedFile, sampname = sampname, projectname, chr)
bamdir <- bambedObj$bamdir; sampname <- bambedObj$sampname
ref <- bambedObj$ref; projectname <- bambedObj$projectname; chr <- bambedObj$chr

# Get raw read depth from the .bam files. Read lengths across all samples are also returned.
coverageObj <- getcoverage(bambedObj, mapqthres = 20)
Y <- coverageObj$Y; readlength <- coverageObj$readlength

# Compute GC content and mappability for each exon target.
gc <- getgc(chr, ref)
mapp <- getmapp(chr, ref)

# Take a sample-wise and exon-wise quality control procedure on the depth of coverage matrix.
#qcObj <- qc(Y, sampname, chr, ref, mapp, gc, cov_thresh = c(20, 4000), length_thresh = c(20, 2000), mapp_thresh = 0.9, gc_thresh = c(20, 80))
#Y_qc <- qcObj$Y_qc; sampname_qc <- qcObj$sampname_qc; gc_qc <- qcObj$gc_qc
#mapp_qc <- qcObj$mapp_qc; ref_qc <- qcObj$ref_qc; qcmat <- qcObj$qcmat
#write.table(qcmat, file.path(outDir, file = paste(projectname, '_', chr, '_qcmat', '.txt', sep='')), sep='\t', quote=FALSE, row.names=FALSE)
#
## Fit Poisson latent factor model for normalization of the read depth data.
#normObj <- normalize(Y_qc, gc_qc, K = 1:lf)
#Yhat <- normObj$Yhat; AIC <- normObj$AIC; BIC <- normObj$BIC
#RSS <- normObj$RSS; K <- normObj$K
#
## Determine the number of latent factors. AIC, BIC, and deviance reduction plots are generated in a .pdf file.
#choiceofK(AIC, BIC, RSS, K, file.path(outDir, filename = paste(projectname, "_", chr, "_choiceofK", ".pdf", sep = "")))
#
## Fit the Poisson log-likelihood ratio based segmentation procedure to determine CNV regions across all samples.
#optK = K[which.max(BIC)]
#finalcall <- segment(Y_qc, Yhat, optK = optK, K = K, sampname_qc, ref_qc, chr, lmax = 200, mode = "integer")
#write.table(finalcall, file.path(outDir, file = paste(projectname, '_', chr, '_', optK, '_CODEX_frac.txt', sep='')), sep='\t', quote=FALSE, row.names=FALSE)
#save.image(file.path(outDir, file = paste(projectname, '_', chr, '_image', '.rda', sep='')), compress='xz')

Y_db <- Y
sampname_db <- sampname 
save(Y_db, sampname_db, gc, mapp, file = file.path(outDir, file = paste(gt_time, '_', chr, '_db', '.rda', sep='')), compress='xz')

# toLatex(sessionInfo())
