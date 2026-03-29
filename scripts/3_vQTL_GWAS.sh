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

######################### Load modules #########################

module load plink2

######################### Define files #########################

cohort="TEDS"   # cohort abbreviation
main_genotype="TEDS" #plink binary file name

phenofile="${cohort}.vQTL.pheno"   # residualised phenotype file produced in step 1 (FID IID + phenotypes)
covarfile="${cohort}_combined.txt"   # file containing covariates
phenoList="dep anx adhd"        # add or remove phenotype names
ancestries="EUR AFR MID"        # add or remove genetic ancestry clusters

######################### IMPORTANT FORMAT CHECKS #########################

# 1. Phenotype / covariate file format must be:
#    FID IID pheno1 pheno2 ... covariates
#
# 2. Column order matters for --covar-numbers:
#    LDAK counts columns INCLUDING FID/IID
#
#    Example:
#    1: FID
#    2: IID
#    3+: covariates
#
#    If covariates are NOT in columns 6–16, update --covar-numbers accordingly
#
# 3. Sex must be coded:
#    1 = male, 2 = female (required for CHRX)
#
# 4. Check genome build and adjust --split-par to hg19 or hg18 when running Xchrom analysis

######################### Step 1: Create relatives file using PLINK2 / KING #########################

# A) Generate KING table and filter on kinship > 0.05, if you don't have this for the sample already, if you have it go to step B
#plink2 --bfile plinkbinaryfile --make-king-table --king-table-filter 0.05 --out "${cohort}.king"

# B)Convert KING output to LDAK-compatible .pairs format

#tail -n +2 "${cohort}.king.kin0" | awk '{print $1,$2,$3,$4,$8*2}' > "${cohort}.pairs"

# Notes:
# - Output format: FID1 IID1 FID2 IID2 relatedness
# - Use this file in vQTL analysis: --relatives "${cohort}.pairs"
# - Threshold 0.05 ≈ 3rd degree relatives

######################### Step 2: Create separate files based on genetic ancestry similarity clusters #########################

for ancestry in $ancestries
do
    keep_file="${ancestry}.keep"
    out_prefix="${cohort}_${ancestry}"
    
    echo "Creating genotype file for ancestry $ancestry"
    
    plink2 --bfile "$main_genotype" \
          --keep "$keep_file" \
          --make-bed \
          --out "$out_prefix"
done

######################### Step 3: Run vQTL GWAS #########################

for pheno in $phenoList
do
    for ancestry in $ancestries
    do
        genotype="${cohort}_${ancestry}"
        output="${cohort}_${pheno}_${ancestry}"
        
        echo "============================================"
        echo "Running LDAK DRM:"
        echo "  Phenotype: $pheno"
        echo "  Ancestry: $ancestry"
        echo "============================================"
        
# CHECK: update if covariates are not in columns 6–16

        ./ldak6.2.drm \
            --linear "$output" \
            --bfile "$genotype" \
            --pheno "$phenofile" \
            --covar "$covarfile" \
            --pheno-name "$pheno" \
            --covar-numbers 6-16 \
            --DRM AUTOSOMES \
            --max-threads 20 \
            --exclude-long-alleles YES \
            --relatives "${cohort}.pairs"

    done
done

######################### Step 4: X chromosome analysis #########################

for pheno in $phenoList
do
    for ancestry in $ancestries
    do
        genotype="${cohort}_${ancestry}"
        output="${cohort}_${pheno}_${ancestry}"
        
        echo "Running LDAK DRM (ChrX): $pheno $ancestry"

        # CHECK: Sex column must exist and be coded 1 = male, 2 = female
        # CHECK: genome build must match your data (hg18 or hg19)
        ./ldak6.2.drm \
            --linear "$output" \
            --bfile "$genotype" \
            --pheno "$phenofile" \
            --sexfile "$covarfile" \
            --pheno-name "$pheno" \
            --DRM CHRX \
            --split-par hg19 \
            --max-threads 20 \
            --exclude-long-alleles YES \
            --relatives "${cohort}.pairs"

    done
done

echo "==========================================="
echo "LDAK DRM vQTL pipeline completed"
echo "==========================================="
