#!/bin/bash -l
######################### LDAK SETUP #########################

# Download LDAK using link provided by Elham and put the ldak6.2.drm file into the directory you'd be running analysis from

# Make LDAK executable (need to do this only once, after downloading the file)
# chmod +x ./ldak6.2.drm

# Create conda environment and install LDAK (only need to do this once, hash out in your bash script)
conda create -n ldak_env -c genomedk ldak6

# Activate environment
conda activate ldak_env  # or use below depending on cluster set up
#conda init ldak_env


# Test LDAK installation
 ./ldak6.2.drm


######################### Define files #########################

cohort="TEDS"   # cohort abbreviation
main_genotype="TEDS" #plink binary file name

phenofile="${cohort}.vQTL.pheno"   # residualised phenotype file produced in step 1 (FID IID + phenotypes)
covarfile="${cohort}_covars.txt"   # file containing covariates ( to use Sex for Xchromosome analyses)
phenoList="dep anx adhd"        # add or remove phenotype names
ancestries="EUR AFR MID"        # add or remove genetic ancestry clusters

######################### IMPORTANT FORMAT CHECKS #########################

# 1. Phenotype / covariate file format must be:
#    FID IID pheno1 pheno2 ...
#    FID IID cov1 cov1 ...
#
# 2. Column order matters for --covar-numbers:
#    LDAK counts columns INCLUDING FID/IID, so --covar-numbers 1-13 will use columns 3-15 (since columns 1 and 2 are always FID, IID).
#    If covariates are NOT in columns 3–15, update --covar-numbers accordingly
#
# 3. Sex must be coded:
#    1 = male, 2 = female (required for CHRX)
#
# 4. Check genome build and adjust --split-par to hg19 or hg38 when running Xchrom analysis

######################### Step 1: Create relatives file using PLINK2 / KING #########################

### skip  A) block if you already have a "${cohort}.king.kin0" file for the sample -> go to step B instead

# A) Thin to HapMap3 SNPs and LD-prune (r2 threshold 0.05), then compute KING kinship. Download link for hm3 snps:https://zenodo.org/records/10515792/files/hm3_no_MHC.list.txt?download=1

hm3_snplist="hm3_no_MHC.list.txt"   # file with HapMap3 SNP IDs, one per line 

# A1. LD-prune directly on HapMap3 SNPs (r2 = 0.05, window 200, step 100)
plink2 --bfile "$main_genotype" \
       --extract "$hm3_snplist" \
       --indep-pairwise 200 100 0.05 \
       --out "${cohort}_pruned"

# A2. Extract pruned HapMap3 SNP set into final "small" bfile (~43k SNPs expected)
plink2 --bfile "$main_genotype" \
       --extract "${cohort}_pruned.prune.in" \
       --make-bed --out small

# A3. Run KING kinship in parallel (20 partitions; ~1hr each on 4 CPUs)
for j in {1..20}; do
  plink2 --bfile small \
         --make-king-table --king-table-filter 0.05 \
         --out "${cohort}.king" \
         --threads 4 --memory 30000 \
         --parallel $j 20
done

# A4. Join partitioned KING output files

cat ${cohort}.king.kin0.{1..20} > "${cohort}.king.kin0"


# B)If you have king files aready for your sample, just convert KING output to LDAK-compatible .pairs format, as per following:


tail -n +2 "${cohort}.king.kin0" | awk '{print $1,$2,$3,$4,$8*2}' > "${cohort}.pairs"

# Notes:
# - Output format: FID1 IID1 FID2 IID2 relatedness
# - Use this file in vQTL analysis: --relatives "${cohort}.pairs"
# - Threshold 0.05 ≈ 3rd degree relatives

######################### Step 2: Run vQTL GWAS #########################

for pheno in $phenoList
do
    for ancestry in $ancestries
    do
        keep_file="${ancestry}.keep"
        output="${cohort}_${pheno}_${ancestry}"
        
        echo "============================================"
        echo "Running LDAK DRM:"
        echo "  Phenotype: $pheno"
        echo "  Ancestry: $ancestry"
        echo "============================================"
        
# CHECK: update covariate numbers as required (--covar-numbers 1-13 selects first to 13th covariates stored in columns 3-15 as columns 1&2 in the file are always FID,IID)

        ./ldak6.2.drm \
            --linear "$output" \
            --bfile "$main_genotype" \
            --keep "$keep_file" \
            --pheno "$phenofile" \
            --pheno-name "$pheno" \
            --DRM AUTOSOMES \
            --max-threads 4 \
            --exclude-long-alleles YES \
            --relatives "${cohort}.pairs"

    done
done
######################### Step 3: X chromosome analysis #########################



for pheno in $phenoList
do
    for ancestry in $ancestries
    do
        keep_file="${ancestry}.keep"
        output="${cohort}_${pheno}_${ancestry}"
        
        echo "Running LDAK DRM (ChrX): $pheno $ancestry"

        ./ldak6.2.drm \
            --linear "$output" \
            --bfile "$main_genotype" \
            --keep "$keep_file" \
            --pheno "$phenofile" \
            --sexfile "$covarfile" \
            --pheno-name "$pheno" \
            --DRM CHRX \
            --split-par hg19 \  ### specify as hg19 or hg38
            --max-threads 4 \
            --exclude-long-alleles YES \
            --relatives "${cohort}.pairs"

    done
done

echo "==========================================="
echo "LDAK DRM vQTL pipeline completed"
echo "==========================================="
