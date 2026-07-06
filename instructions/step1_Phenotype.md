# Step 1: Prepare GWAS Phenotypes

## What this step does

- **Generates vQTL GWAS phenotypes** residualised for covariates and standardised. **Note**: raw input phenotype is the pro-rated mean score, rather than total score.
- **Minimum required covariates:** `age`, `Sex`, their interaction, and 10 principal components (`PC1`–`PC10`).  
  **Important:** Sex must be coded `1 = male`, `2 = female` in both the phenotype and `.fam` files. This is required for X-chromosome analyses.  

- **Computes descriptive statistics** for both original and residualised phenotypes, including summaries for covariates (`age`, `Sex`, `PCs`) and `N`, `Mean`, `SD`, `Min`, `Max`, `Variance`, `Skew`, `Kurtosis`.

## Required input files

- Phenotype+covariate file must include:
  - `FID`, `IID`
  - Phenotype columns
  - **Minimum covariates:** `Sex`, `age`, and `PCs 1–10`  
- Missing phenotypic values should be denoted as `NA` (not `-9`).


## Script to run

Run the R script [1_PreparePheno.R](../scripts/1_PreparePheno.R) to residualise phenotypes by `age`, `Sex`, and `PCs 1–10`, and to generate cohort descriptive statistics. Ensure your input file contains all required columns.
R script requires installing psych and data.table packages.

## Output

- Residualised phenotypes ready for vQTL analysis:  
  `cohort.vQTL.pheno`  
- Descriptive statistics file:  
  `cohort_descStats.csv` (includes raw + residualised phenotype stats, with covariate summaries)

## Phenotype naming convention

Please use the following abbreviations for the phenotypes.

| Phenotype                        | Code  |
|---------------------------------|-------|
| Depressive symptoms              | dep   |
| Anxiety symptoms                 | anx   |
| ADHD symptoms                    | adhd  |
| Autism symptoms                  | asd   |
| Psychotic-like experiences       | ple   |
| Neuroticism                      | neuro |
| Well-being                        | well  |
| Educational attainment           | edu   |
| Height                           | height|
| Body Mass Index (BMI)            | bmi   |


