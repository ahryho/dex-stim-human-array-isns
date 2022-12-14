# Subset DNAm based on  the median absolute deviation (MAD) score

# 1. Set up global variables

args              <- commandArgs(T)
treatment         <- as.character(args[1]) 
mad_thr           <- as.character(args[2]) 
in_gds_fn         <- as.character(args[3]) 
out_gds_fn        <- as.character(args[4]) 

setwd("/binder/mgp/workspace/2020_DexStim_Array_Human/dex-stim-human-isns/input/dnam/")

source("~/kul/dex-stim-human-array-isns/code/00_functions/load_pkgs.R")
source("~/kul/dex-stim-human-array-isns/code/00_functions/load_gds_files.R")

pkgs_list <- c("data.table", "gdsfmt", "arrow")

LoadPackages(pkgs_list)

# 2. Load data

# treatment   <- "dex"
# in_gds_fn   <- paste0("gds/methyl_beta_mtrx_corrected_for_cov","_", treatment, ".gds")
# mad_thr <- 80 # = 80%

dnam_mtrx   <- LoadMethyl(in_gds_fn, is_mad = F)

mad_val_fn  <- paste0("mad_filtered/mad_score_methyl_beta.csv") 
mad_val_df  <- fread(mad_val_fn)

# 3. Subset mad values based on threshold: take the intersection of baseline and dex CpGs 
# The CpGs should be the same for two time points

mad_val_thr_veh  <- mad_val_df[treatment == "veh"][perc >= (mad_thr)][, CpG_ID]
mad_val_thr_dex  <- mad_val_df[treatment == "dex"][perc >= (mad_thr)][, CpG_ID]

mad_val_thr_cpgs <- intersect(mad_val_thr_veh, mad_val_thr_dex)

# 4. Subset

dnam_sub_mtrx <- dnam_mtrx[, colnames(dnam_mtrx) %in% mad_val_thr_cpgs]
cpg_ids       <- colnames(dnam_sub_mtrx)

# 5. Create a GDS object

## 5.1. Get CpG coordinates

cpg_loc_fn <- "cpg_locations.csv"
cpg_loc    <- read_delim_arrow(cpg_loc_fn, delim = ";")

order_idx  <- match(cpg_ids, cpg_loc$CpG_ID)
cpg_loc    <- cpg_loc[order_idx, ]

## 5.2. Create a GDS object

gds_file <- createfn.gds(out_gds_fn)

add.gdsn(gds_file, name = "beta_mtrx", val = dnam_sub_mtrx)
add.gdsn(gds_file, name = "cpg_id", val =  cpg_ids)
add.gdsn(gds_file, name = "sample_id", val = rownames(dnam_sub_mtrx))
add.gdsn(gds_file, name = "cpg_chr", val = cpg_loc$chr)
add.gdsn(gds_file, name = "cpg_pos", val = cpg_loc$pos)

print("Check GDS file: ", quote = F)
show(gds_file)

closefn.gds(gds_file)
