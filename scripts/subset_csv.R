#!/usr/bin/env Rscript

df <- read.csv("~/eButterfly-422Final/data/ebutterfly_sdm_data_updated.csv")

for (i in unique(df$species_id)) {
    df <- df[which(df$species_id == i),]
    write.csv(df, file = paste0(i,"-ebutterfly.csv"))
    df <- read.csv("~/eButterfly-422Final/data/ebutterfly_sdm_data_clean.csv")
}
