# 1. Set up global variables

args              <- commandArgs(T)
in_gds_fn         <- as.character(args[1]) 
out_gds_fn_prefix <- as.character(args[2]) 

# in_gds_fn <- "ld_pruned/gds/dex_geno_imputed_maf_from_gen.gds"
# out_gds_fn_prefix <- "ld_pruned/gds/"

# 2. Load packages

setwd("/binder/mgp/workspace/2020_DexStim_Array_Human/dex-stim-human-isns/input/snps/")

source("~/kul/dex-stim-human-array-isns/code/00_functions/load_pkgs.R")

pkgs_list <- c("dplyr",
               "gdsfmt", "SNPRelate")

LoadPackages(pkgs_list)

# 3. Load SNP GDS object

gds_file <- openfn.gds(in_gds_fn)

mtrx       <- read.gdsn(index.gdsn(gds_file, "genotype"))
snp_ids    <- read.gdsn(index.gdsn(gds_file, "snp.id"))
chr        <- read.gdsn(index.gdsn(gds_file, "snp.chromosome"))
pos        <- read.gdsn(index.gdsn(gds_file, "snp.position"))
sample_ids <- read.gdsn(index.gdsn(gds_file, "sample.id"))

closefn.gds(gds_file)

# 4. Create a genomic location df

loc_df     <- data.frame(SNP = snp_ids, chr, pos)
loc_lst    <- split(loc_df, f = loc_df$chr)

# 5. Prepare mtrx

colnames(mtrx) <- snp_ids

# 6. Create and save GDS for each chrom

system(paste0("mkdir -p ", out_gds_fn_prefix, "chromosomes", treatment))

lapply(1:length(loc_lst), function(chr){
  out_gds_fn   <- paste0(out_gds_fn_prefix, "chromosomes/dex_geno_chr", chr, ".gds")
  
  loc_chr_df <- loc_lst[[chr]]
  mtrx_chr   <- mtrx[, colnames(mtrx) %in% loc_chr_df$SNP]
  
  gds_file   <- createfn.gds(out_gds_fn)
  
  add.gdsn(gds_file, name = "genotype", val = mtrx_chr)
  add.gdsn(gds_file, name = "snp_id", val = loc_chr_df$SNP)
  add.gdsn(gds_file, name = "snp_chr", val = loc_chr_df$chr)
  add.gdsn(gds_file, name = "snp_pos", val = loc_chr_df$pos)
  add.gdsn(gds_file, name = "sample_id", val = sample_ids)
  
  show(gds_file)
  
  closefn.gds(gds_file)
})
  