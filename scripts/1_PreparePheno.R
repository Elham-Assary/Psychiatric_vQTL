###################### prepare vQTL phenotype, get descriptive statistics######################
library(data.table)
library(psych)

#########input and output files #######
cohort <- "Cohort"                  #cohort acronym
input_file <- "pheno_covar.txt"  # combined phenotypes + covariates file name (assumes columns FID and IID, followed by phenotypes and covars)
phenos <- c("dep", "anx", "adhd")  # list of phenotypes, add and remove as appropriate
covars <- c("age","Sex","PC1","PC2","PC3","PC4","PC5","PC6","PC7","PC8","PC9","PC10")    # list of covariate names for residualisation 
#note Sex with caputal S, and males should be coded as 1, female=2), age2 and interaction terms are created when residualising

output_pheno <- paste0(cohort, ".vQTL.pheno")      ## output phenotype file name 
output_stats <- paste0(cohort, "_descStats.csv")     ##descritive statistics output file

# Load data 
df <- fread(input_file)
df$FID <- as.character(df$FID)
df$IID <- as.character(df$IID)


# Check that Sex is coded as 1 and 2 only (allow NA)
invalid_vals <- setdiff(unique(df$Sex), c(1, 2, NA))
if (length(invalid_vals) > 0) {
  stop(paste("Error: Invalid values in 'Sex':", paste(invalid_vals, collapse = ", ")))
}

# output for residualised phenotypes
resid_df <- df[, .(FID, IID)]

for (ph in phenos) {
  cat("Processing phenotype:", ph, "\n")
  
  # Prepare the list of additional covariates (everything except Sex and age as listed above in covars)
  other_covars <- covars[!covars %in% c("Sex", "age")]
  
  # Construct the interaction terms + main covars
  formula <- as.formula(
    paste(ph, "~ Sex * (age + I(age^2)) +", paste(other_covars, collapse=" + "))
  )
  
  model <- lm(formula, data=df, na.action = na.exclude)
  
  # Extract residuals
  res <- resid(model)
  
  # Standardise residuals (mean=0, SD=1)
  res_std <- scale(res)
  
  # Convert from matrix to numeric vector
  resid_df[[ph]] <- as.numeric(res_std)
}

####### get descriptive stats #####

# Function to calculate descriptive statistics
desc_stats <- function(data){
  data_num <- data[, sapply(data, is.numeric), with=FALSE]
  stats <- data.frame(
    phenotype = names(data_num),
    N = sapply(data_num, function(x) sum(!is.na(x))),
    Mean = sapply(data_num, function(x) mean(x, na.rm = TRUE)),
    Var = sapply(data_num, function(x) var(x, na.rm = TRUE)),
    SD = sapply(data_num, function(x) sd(x, na.rm = TRUE)),
    Min = sapply(data_num, function(x) min(x, na.rm = TRUE)),
    Max = sapply(data_num, function(x) max(x, na.rm = TRUE)),
    Skew = sapply(data_num, function(x) psych::skew(x, na.rm = TRUE)),
    Kurtosis = sapply(data_num, function(x) psych::kurtosi(x, na.rm = TRUE)),
    NAs = sapply(data_num, function(x) sum(is.na(x)))
  )
  return(stats)
}

raw_phen <- desc_stats(df[, ..phenos])
vqtl_phen <- desc_stats(resid_df[, ..phenos])

# Per-phenotype covariate stats 
                      
get_covar_stats <- function(pheno_vec) {
  keep <- !is.na(pheno_vec)
  data.frame(
    Mean_age = mean(df$age[keep], na.rm = TRUE),
    SD_age   = sd(df$age[keep], na.rm = TRUE),
    N_male   = sum(df$Sex[keep] == 1, na.rm = TRUE),
    N_female = sum(df$Sex[keep] == 2, na.rm = TRUE)
  )
}

raw_covar_df  <- do.call(rbind, lapply(phenos, function(ph) get_covar_stats(df[[ph]])))
vqtl_covar_df <- do.call(rbind, lapply(phenos, function(ph) get_covar_stats(resid_df[[ph]])))

raw_phen  <- cbind(raw_phen,  raw_covar_df)
vqtl_phen <- cbind(vqtl_phen, vqtl_covar_df)

raw_phen$Data  <- "raw_phen"
vqtl_phen$Data <- "vqtl_phen"

# Reorder columns
cols_order <- c("phenotype", "Data", setdiff(names(raw_phen), c("phenotype","Data")))
all_stats <- rbind(raw_phen[, cols_order], vqtl_phen[, cols_order])

########Save outputs ######
fwrite(resid_df, output_pheno, sep="\t", quote=FALSE, na="NA")
cat("Residualised phenotypes saved to:", output_pheno, "\n")

fwrite(all_stats, output_stats, sep=",", quote=FALSE, na="NA")
cat("Descriptive statistics saved to:", output_stats, "\n")
                                       
