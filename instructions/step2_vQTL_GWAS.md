
# Step 2: vQTL Analysis

## What this step does

- **Performs variance QTL (vQTL) GWAS analysis**  using DRM method incorporated in LDAK (https://dougspeed.com/drm/), accounting for relatedness in the sample.
- Loops over **both phenotypes and genetic ancestry groups**, producing results for each combination.  
- Runs analyses separately for:
  - **Autosomes**
  - **X chromosome** stratified by sex

## Required input files 

- **main genotype file:** PLINK binary files `.bed/.bim/.fam` (e.g., `cohort.bed`)
- **phenotype file:** `cohort_vQTL.pheno` must include `FID`, `IID`, phenotype columns. See step 1 for phenotype preparation.
- **covariates file:** including `FID`, `IID`, `10 PCs` and must include `Sex` (males=1, females=2) for Xchromosome analysis, plus any other cohort specific covariates.
- **ancestry keep file:** lists `FID` and `IID` of individuals to include in genetic ancestry similarity clusters (e.g., `AFR.keep`, `EUR.keep`)
- **relatives file:** obtained via KING or Plink2. Script includes code for how to obtain this in Plink2, if file not available already.
- **shell script:** [2_vQTL_GWAS.sh](../scripts/2_vQTL_GWAS.sh) to run the variance QTL analysis

## Required programes

Plink 2: [https://www.cog-genomics.org/plink/](https://www.cog-genomics.org/plink/2.0/) to obtain relatives file, if not already avaiable.

LDAK (DRM): https://dougspeed.com/drm/

> 🔹 Contact **Elham** to obtain the LDAK executable.  
> Place it in your working directory and make it executable:
> ```
> chmod +x ldak6.2.drm
> ```

## Important notes

- You must define at least one ancestry cluster in the script (`ancestries` variable), **even if you are analysing the data using a single genetic ancestry** due to small sample size for example. In this case, use a `.keep` file containing FID and IID of study sample. This ensures naming compatibility across cohorts for QC.
- **Genotype QC** should be relatively light **(MAF <.01, missingness > 5%, but no HWE filtering)** , and the analysis must be run on **biallelic variants only**. 
- The **relatives file** must be in LDAK `.pairs` format: FID1 IID1 FID2 IID2 relatedness. See script for how to obtain this or format an existing Plink/KING derived file.
- LDAK **counts columns including FID/IID** for covariates, so --covar-numbers 1-10 will use columns 3-13 (since columns 1 and 2 are always FID, IID, and first covariate is stored in col 3, second in col 4, etc). Ensure you **input correct covar numbers** in your script.
- The main analysis is run on **autosomes** (`--DRM AUTOSOMES`). See below for X chromosome analysis if data is available.
- If your **dataset is larger than 200k**, you should divide by chromosome and concatenate output to reduce run time for the job.


## X chromosome analysis

A separate analysis is run using:
- `--DRM CHRX`
- `--sexfile`
- `--split-par hg19`
  
Notes:
  
- The `sexfile` can be the **covariate file, or a combined pheno+covar file**, as long as it contains:
  - `FID` ,  `IID`, and a column labelled `Sex` coded as 1=male, 2=female

- The analysis is run **separately for males and females**, producing:
  - `*.DRM.males`
  - `*.DRM.females`
  - Correct genome build must be specified (e.g., `--split-par hg19`)


## Output

- vQTL result files for each phenotype and ancestry in autosomes , such as `cohort_phenotype_ancestry.DRM.all` 
- vQTL results file for Xchromosome for each phenotype and ancestry, for males and females: `cohort_phenotype_ancestry.DRM.males` and `cohort_phenotype_ancestry.DRM.females`

## Genetic ancestry clusters and codes

| Code | description |
|------|-------------|
| AFR  | African  |
| HIS  | Hispanic/Latino |
| AMR  | American Admixed |
| EAS  | East Asian |
| EUR  | European |
| MID  | Middle Eastern  |
| SAS  | South Asian  |
| OCE  | Oceanian |
