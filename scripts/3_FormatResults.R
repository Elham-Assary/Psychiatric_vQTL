#######################################################################################################
#Format results: get hwe per ancestry and combine with vQLT results and INFO (for autosomes and Xchromosome males/females if avaialable)
#######################################################################################################

# module load plink2 in the .sh job script to call on later if running hwe per ancestry

library(data.table)


##########################
# Set variables - edit as necessary
##########################

cohort <- "TEDS"                      # cohort abbreviation
phenotypes <- c("dep", "anx", "adhd") # phenotype names
ancestries <- c("EUR", "AFR", "MID")  # ancestry clusters
main_genotype <- "TEDS"               # main dataset plink binary files prefix for getting hwe 
info_file <- "INFO.txt"               # path to INFO file, with two columns header SNP, INFO

## also need ancestry.keep files for relevant ancestries, to get hwe in step1 (file name is assumed to be in the formate of ancestrycode.keep, e.g. EUR.keep)

##########################
# Function: combine DRM + HWE + INFO
##########################

combine_vqtl <- function(drm_file, hwe_file = NULL, info_file = NULL) {
  dt <- fread(drm_file)

    # Standardise variant ID column to SNP
  if ("Predictor" %in% names(dt)) {
    setnames(dt, "Predictor", "SNP")
  } else if (!"SNP" %in% names(dt)) {
    stop("No variant ID column found in ", drm_file,
         ". Expected 'Predictor' or 'SNP'. Columns present: ",
         paste(names(dt), collapse = ", "))
  }
  
   if (!is.null(hwe_file)) {
    hwe_dt <- fread(hwe_file)
    setnames(hwe_dt, "#CHROM", "CHROM", skip_absent = TRUE)
    
    if ("P" %in% names(hwe_dt)) {
      hwe_dt <- hwe_dt[, .(SNP = ID, HWE = P)]
    } else {
      stop("No P column found in ", hwe_file,
           ". Columns present: ", paste(names(hwe_dt), collapse = ", "))
    }
    
    dt <- merge(dt, hwe_dt, by = "SNP", all.x = TRUE)
  }
  
  if (!is.null(info_file)) {
    info_dt <- fread(info_file)
    dt <- merge(dt, info_dt, by = "SNP", all.x = TRUE)
  }
    return(dt)
}

##########################
# Step 1: Run HWE per ancestry and merge autosomes DRM.all
##########################
for (ancestry in ancestries) {
  keep_file <- paste0(ancestry, ".keep")
  
  cat("\n=== Processing ancestry:", ancestry, "===\n")
  
  # Run HWE per ancestry using the keep file
  cat("Running PLINK2 --hardy (autosomes + X) for ancestry", ancestry, "...\n")
  system(paste("plink2 --bfile", main_genotype,
               "--keep", keep_file,
               "--hardy midp --out", paste0(cohort, "_", ancestry)))
  
  # Autosomes DRM.all
  for (pheno in phenotypes) {
    drm_file <- paste0(cohort, "_", pheno, "_", ancestry, ".DRM.all")
    hwe_file <- paste0(cohort, "_", ancestry, ".hardy")
    dt <- combine_vqtl(drm_file, hwe_file, info_file)
    
    output_file <- paste0(cohort, "_", pheno, "_", ancestry, ".vqtl.txt")
    fwrite(dt, output_file, sep = "\t", quote = FALSE)
    system(paste0("gzip -f ", output_file))
    cat("Saved:", paste0(output_file, ".gz\n"))
  }
}

##########################
# Step 2: X chromosome females and males merge with HWE and INFO
##########################
for (ancestry in ancestries) {
  x_hwe_file <- paste0(cohort, "_", ancestry, ".hardy.x")
  
  if (!file.exists(x_hwe_file)) {
    cat("No X chromosome HWE file for ancestry", ancestry, "- skipping X chromosome step.\n")
    next
  }
  
  for (pheno in phenotypes) {
    # Females
    drm_females <- paste0(cohort, "_", pheno, "_", ancestry, ".DRM.females")
    dt_f <- combine_vqtl(drm_females, x_hwe_file, info_file)
    out_f <- paste0(cohort, "_", pheno, "_", ancestry, ".X_females.vqtl.txt")
    fwrite(dt_f, out_f, sep = "\t", quote = FALSE)
    system(paste0("gzip -f ", out_f))
    cat("Saved female X chr vQTL:", paste0(out_f, ".gz\n"))
    
    # Males (no HWE)
    drm_males <- paste0(cohort, "_", pheno, "_", ancestry, ".DRM.males")
    dt_m <- combine_vqtl(drm_males, NULL, info_file)
    out_m <- paste0(cohort, "_", pheno, "_", ancestry, ".X_males.vqtl.txt")
    fwrite(dt_m, out_m, sep = "\t", quote = FALSE)
    system(paste0("gzip -f ", out_m))
    cat("Saved male X chr vQTL:", paste0(out_m, ".gz\n"))
  }
}
cat("\nAll phenotypes and ancestries processed successfully.\n")
