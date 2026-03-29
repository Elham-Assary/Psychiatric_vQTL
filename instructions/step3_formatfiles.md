## Step 3: Format final summary statistics file 

### What this step does

- **Generates Hardy-Weinberg Equilibrium (HWE) statistics** per ancestry using PLINK.
- **Merges vQTL GWAS summary statistics** with HWE and INFO scores for later QC.  
  

### Required input files 

- **genotype files:** PLINK binary files `.bed/.bim/.fam` to obtain HWE pvalues per ancestry
- **vQTL sumstats** produced in Step 2: `cohort_phenotype_ancestry.DRM.all` and if available `cohort_phenotype_ancestry.DRM.males` and `cohort_phenotype_ancestry.DRM.females`
- **ancestry keep files** containing `FID` and `IID` of individuals for each ancestry cluster (e.g., `EUR.keep`, `AFR.keep`)
- **INFO file** containing SNP imputation quality score (e.g., `INFO.txt` with columns `SNP, INFO`)
- **Rscript to format results**: [FormatResults.R](scripts/FormatResults.R)
  
 ### Required programs 
 
- **Plink 2**
- **R**: requires the `data.table` R package.
  

### Output

- **Autosomes:** `cohort_phenotype_ancestry.vqtl.txt.gz`
- and if Xchromosome analysis conducted: 
  - **X chromosome females:** `cohort_phenotype_ancestry.X_females.vqtl.txt.gz`
  - **X chromosome males:** `cohort_phenotype_ancestry.X_males.vqtl.txt.gz`
