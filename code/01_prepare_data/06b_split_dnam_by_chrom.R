setwd("/binder/mgp/workspace/2020_DexStim_Array_Human/dex-stim-human-isns/input/dnam/")

source("~/kul/dex-stim-human-array-isns/code/00_functions/load_pkgs.R")

pkgs_list <- c("dplyr",
               "gdsfmt", "SNPRelate",
               "parallel", "foreach", "doParallel", 
               "tictoc")

LoadPackages(pkgs_list)

# 1. Set up global variables

args   <- commandArgs(T)
gds_fn <-  as.character(args[1]) 

treatment <- "veh"
gds_fn    <- paste0("gds/methyl_beta_mtrx_corrected_for_cov",
                    "_", treatment, ".gds")

# 2. Load SNP GDS object

gds_file <- openfn.gds(gds_fn)

mtrx       <- read.gdsn(index.gdsn(gds_file, "beta_mtrx"))
cpg_ids    <- read.gdsn(index.gdsn(gds_file, "cpg_id"))
chr        <- read.gdsn(index.gdsn(gds_file, "cpg_chr"))
pos        <- read.gdsn(index.gdsn(gds_file, "cpg_pos"))
sample_ids <- read.gdsn(index.gdsn(gds_file, "sample_id"))

closefn.gds(gds_file)

# 3. Create a genomic location df

loc_df     <- data.frame(CpG_ID = cpg_ids, chr, pos)
loc_lst    <- split(loc_df, f = loc_df$chr)

# 4. Prepare mtrx

colnames(mtrx) <- cpg_ids

# 5. Create and save GDS for each chrom

lapply(2:length(loc_lst), function(chr){
  out_gds_fn   <- paste0("gds/chromosomes/", treatment, "/methyl_beta_mtrx_corrected_for_cov",
                         "_", treatment, "_chr", chr, ".gds")
  
  loc_chr_df <- loc_lst[[chr]]
  mtrx_chr   <- mtrx[, colnames(mtrx) %in% loc_chr_df$CpG_ID]
  
  gds_file   <- createfn.gds(out_gds_fn)
  
  add.gdsn(gds_file, name = "beta_mtrx", val = mtrx_chr)
  add.gdsn(gds_file, name = "cpg_id", val = loc_chr_df$CpG_ID)
  add.gdsn(gds_file, name = "cpg_chr", val = loc_chr_df$chr)
  add.gdsn(gds_file, name = "cpg_pos", val = loc_chr_df$pos)
  add.gdsn(gds_file, name = "sample_id", val = sample_ids)
  
  show(gds_file)
  
  closefn.gds(gds_file)
})
  