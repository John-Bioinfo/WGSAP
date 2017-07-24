**********************************
 DisGeNET, a discovery platform for human diseases and their genes
**********************************

DisGeNET is a discovery platform integrating information on gene-disease associations from several public data sources and the literature. The DisGeNET data is made available under the Open Database License. For more information, see the Legal Notices page (http://www.disgenet.org/ds/DisGeNET/html/legal.html).
The files in the current directory contain the data corresponding to the latest release (version 4.0, June 2016). The information is separated by tab.

curated_gene_disease_associations.txt 		=> Gene Disease associations from UniProt, ClinVar, Orphanet, the GWAS Catalog, and Comparative Toxicogenomics Database (human data)
befree_gene_disease_associations.txt 		=> Gene Disease associations obtained using BeFree System
all_gene_disease_associations.txt 		=> All Gene Disease associations in DisGeNET


The columns in the files are:
geneId 		-> Entrez Gene Identifier
geneSymbol	-> Official Gene Symbol
geneName 	-> Full Gene Name
diseaseId 	-> UMLS concept unique identifier
diseaseName 	-> Name of the disease	
score		-> DisGENET score for the Gene Disease association
NofPmids	-> total number of papers reporting the Gene Disease association
NofSnps		-> total number of SNPs associated to the Gene Disease association
source		-> Original source reporting the Gene Disease association


befree_snps_sentences_pubmeds.tsv.gz		=> Gene Disease associations obtained using BeFree System
The columns in the files are:
snpId		-> dbSNP Identifier of the variant linked to the Gene Disease association
pubmedId	-> PMID identifier of the paper supporting the association
geneId		-> Entrez Gene Identifier
geneSymbol	-> Official Gene Symbol
diseaseId	-> UMLS concept unique identifier
diseaseName	-> Name of the disease	
sentence	-> Sentence supporting the association in the publication


all_snps_sentences_pubmeds.tsv.gz		=> All Gene Disease associations in DisGeNET
The columns in the file are:
snpId		-> dbSNP Identifier of the variant linked to the Gene Disease association
pubmedId	-> PMID identifier of the paper supporting the association
geneId		-> Entrez Gene Identifier
geneSymbol	-> Official Gene Symbol
diseaseId	-> UMLS concept unique identifier
diseaseName	-> Name of the disease	
sourceId	-> Original source reporting the Gene Disease association
sentence	-> Sentence supporting the association in the publication
score		-> DisGENET score for the Gene Disease association
year		-> Year of publication
geneSymbol_dbSNP-> Gene according to dbSNP database 
CHROMOSOME 	-> Chromosome, according to dbSNP database       
POS  		-> Chromosome Position, according to dbSNP database   
REF 	 	-> Reference Allele, according to dbSNP database   
ALT 		-> Reference Allele, according to dbSNP database  

befree_results_only_version_4.0.tar.gz	=> Publications supporting the Gene Disease associations obtained using BeFree System (2015-2016)
The columns in the files are:
PMID		-> PMID identifier of the paper supporting the association
SECTION		-> Section of the abstract supporting the evidence
SECTION_NUM	-> Number of the section of the abstract supporting the evidence
SENTENCE_NUM	-> Number of the sentence supporting the evidence
GENE_ID		-> Entrez Gene Identifier
DISEASE_ID	-> UMLS concept unique identifier
SENTENCE	-> Sentence supporting the association in the publication with mentions tagged


Disclaimer

Except where expressly provided otherwise, the site, and all content, materials, information, software, products and services provided on the site, are provided on an "as is" and "as available" basis. The IBIgroup expressly disclaims all warranties of any kind, whether express or implied, including, but not limited to, the implied warranties of merchantability, fitness for a particular purpose and non-infringement. The IBI group makes no warranty that:

    a. the site will meet your requirements 

    b. the site will be available on an uninterrupted, timely, secure, or error-free basis (though IBI will undertake best-efforts to ensure continual uptime and availability of its content) 

    c. the results that may be obtained from the use of the site or any services offered through the site will be accurate or reliable 

    d. the quality of any products, services, information, or other material obtained by you through the site will meet your expectations 

Any content, materials, information or software downloaded or otherwise obtained through the use of the site is done at your own discretion and risk. The IBI group shall have no responsibility for any damage to your computer system or loss of data that results from the download of any content, materials, information or software. The IBI group reserves the right to make changes or updates to the site at any time without notice. 

If you have any further questions, please email us at support@disgenet.org

