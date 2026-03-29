# Variance-QTL GWAS of psychiatric and neurodevelopmental traits

This project aims to identify genetic loci associated with variance in psychiatric, neurodevelopment phenotypes through meta-analysis of vQTL results across participating studies. Each study will conduct within-cohort vQTL GWAS analyses using several psychiatric and related phenotypes. 
**See SOP for details of the project.**


### Contact

**Contact Elham Assary: elham.1.assary@kcl.ac.uk if you have any questions.**

### Instructions

Step-by-step instructions and details on the analysis pipeline are available in the [instructions folder](instructions/) in this repository.  
You can access individual steps here:

- [step1_Phenotype.md](instructions/step1_Phenotype.md) 
- [step2_vQTL_GWAS.md](instructions/step2_vQTL_GWAS.md) 
- [step3_formatfiles.md](instructions/step3_formatfiles.md) 
- [step4_upload_data.md](instructions/step4_upload_data.md) 


### Overview

**Phenotypes of interest:**

1.	Depressive symptoms
2.	Anxiety symptoms 
3.	ADHD symptoms
4.	Autism symptoms
5.	Psychotic symptoms 
6.	Neuroticism
7.	Well-being
8.	Educational attainment
9.	Height
10.	BMI 

**GWAS phenotypes:**

The GWAS phenotype is the symptom score/ continuos score, residualised for sex and age, their interaction, and 10 genetic principal components. The residuals are standardised and used as predictors in the vQTL GWAS. 

The R script to construct the phenotypes, and extract descriptive statistics of the data are in [PreparePheno.R](scripts/PreparePheno.R)


**Variance GWAS analyses:**

vQTL analysis is conducted via [LDAK](https://dougspeed.com/drm/). Contact Elham to obtain the download link for LDAK-DRM.

The script to conduct vQTL analysis is [vQTL_GWAS.sh](scripts/vQTL_GWAS.sh).


**Data to be returned:**

Individual-level data sharing is not required, as meta-analyses will be performed on summary-level data only. Each cohort should upload the following files via the provided link.

1. **Summary statistics** — gzipped, tab-delimited text files for each ancestry group.  
The script [FormatResults.R](scripts/FormatResults.R) will obtain HWE per ancestry, merge with the INFO.txt file, and format the summary statistics into the required format:

   - `cohort_pheno_ancestry.vqtl.txt.gz`  
   - If X chromosome analysis is conducted:  
     - `cohort_phenotype_ancestry.X_males.vqtl.txt.gz`  
     - `cohort_phenotype_ancestry.X_females.vqtl.txt.gz`  

2. **Cohort/analyst information document** — completed template named `cohort_info.doc`.  
The script [PreparePheno.R](scripts/PreparePheno.R) produces a descriptive statistics file (`cohort_descStats.csv`) which can be used to fill out the cohort summary document.

## Overview of the workflow

![Pipeline overview](images/pipeline_overview.jpg)


