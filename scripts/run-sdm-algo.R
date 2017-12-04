#!/usr/bin/env Rscript

# Script to run Species Distribution Model with a variety of algorithms
# Jeff Oliver
# jcoliver@email.arizona.edu
# 2017-11-20

rm(list = ls())

################################################################################
# SETUP
# Gather path information
# Load dependancies
args = commandArgs(trailingOnly = TRUE)
usage.string <- "Usage: Rscript --vanilla scripts/run-sdm-algo.R <path/to/data/file> <output-file-prefix> <path/to/output/directory/> <algorithm string: CTA, GLM, or RF>[optional] <number of background replicates>[optional] <threshold for occurrance>[optional]"

# Make sure a readable file is first argument
if (length(args) < 1) {
  stop(paste("run-sdm requires an input file", 
             usage.string,
             sep = "\n"))
}

infile <- args[1]
if (!file.exists(infile)) {
  stop(paste0("Cannot find ", infile, ", file does not exist.\n", usage.string, "\n"))
}

if (file.access(names = infile, mode = 4) != 0) {
  stop(paste0("You do not have sufficient access to read ", infile, "\n"))
}

# Make sure the second argument is there for output file prefix
if (length(args) < 2) {
  stop(paste("run-sdm requires an output file prefix",
             usage.string,
             sep = "\n"))
}
outprefix <- args[2]

# Make sure the third argument is there for output directory
if (length(args) < 3) {
  stop(paste("run-sdm requires an output directory",
             usage.string,
             sep = "\n"))
}
outpath <- args[3]

# Make sure the path ends with "/"
if (substring(text = outpath, first = nchar(outpath), last = nchar(outpath)) != "/") {
  outpath <- paste0(outpath, "/")
}

# See if they set algorithm
sdm.algorithm <- "CTA"
if (length(args) > 3) {
  tmp.algorithm <- toupper(args[4])
  if (args[4] %in% c("CTA", "GLM", "RF")) {
    sdm.algorithm <- tmp.algorithm
  }
}

# Check number of background replicates is ok (if provided)
bg.replicates <- 10
rep.threshold <- 0.5
if (length(args) > 4) {
  temp.reps <- as.integer(args[5])
  if (!is.na(temp.reps)) {
    bg.replicates <- temp.reps
  }
  
  # Check threshold (if provided)
  if (length(args) > 5) {
    temp.threshold <- as.numeric(args[6])
    if (!is.na(temp.threshold) && temp.threshold > 0.0 && temp.threshold <= 1.0) {
      rep.threshold <- temp.threshold
    }
  }
}


# Load dependancies, keeping track of any that fail
required.packages <- c("rgdal", "raster", "sp", "dismo", "maptools", "gtools", "SSDM")
missing.packages <- character(0)
for (one.package in required.packages) {
  if (!suppressMessages(require(package = one.package, character.only = TRUE))) {
    missing.packages <- cbind(missing.packages, one.package)
  }
}

if (length(missing.packages) > 0) {
  stop(paste0("Missing one or more required packages. The following packages are required for run-sdm: ", paste(missing.packages, sep = "", collapse = ", ")), ".\n")
}
rm(one.package, required.packages, missing.packages)

# Load functions from files in functions directory
functions <- list.files(path = "../../functions", pattern = ".R", full.names = TRUE)
for(f in 1:length(functions)) {
  source(file = functions[f])
}
rm(f, functions)

################################################################################
# DATA
# Read data and set rng seed
orig.data <- read.csv(file = infile)
obs.data <- orig.data[, c("scientific_name", "longitude", "latitude", "month")]
set.seed(19470909)

################################################################################
# ANALYSIS
# Run modeling and extract rasters

# min.max <- MinMaxCoordinates(x = obs.data)
# geographic.extent <- extent(x = min.max)
min.max <- c(-165, -52, 15, 75) # North America
names(min.max) <- c("min.lon", "max.lon", "min.lat", "max.lat")
geographic.extent <- extent(min.max)

# Get the biolim data
bioclim.data <- getData(name = "worldclim",
                        var = "bio",
                        res = 2.5, # Could try for better resolution, 0.5, but would then need to provide lat & long...
                        path = "..")
bioclim.data <- stack(crop(x = bioclim.data, y = geographic.extent))

sdms <- SDMAlgos(data = obs.data, 
                 env.data = bioclim.data,
                 sdm.algorithm = sdm.algorithm, 
                 bg.replicates = bg.replicates)

presence.raster <- sdms$presence
presence.raster <- presence.raster > bg.replicates * rep.threshold
presence.raster[presence.raster <= 0] <- NA
probabilities.raster <- sdms$probabilities
probabilities.raster[probabilities.raster <= 0] <- NA

################################################################################
# OUTPUT
# Save graphics image of presence/absence
# Save rasters of presence/absence and occurrence probabilities

# Save image to file
data(wrld_simpl) # Need this for the map

# Could restrict to observed distribution, but very coarse (giant pixels)
# obs.min.max <- MinMaxCoordinates(x = obs.data)

png.name <- paste0(outpath, outprefix, "-", sdm.algorithm, "-prediction.png")
png(filename = png.name)
par(mar = c(3, 3, 3, 1) + 0.1)
plot(wrld_simpl, 
     xlim = c(min.max["min.lon"], min.max["max.lon"]), 
     ylim = c(min.max["min.lat"], min.max["max.lat"]), 
     col = "#F2F2F2",
     axes = TRUE)
plot(presence.raster, 
     main = "Presence/Absence",
     legend = FALSE,
     add = TRUE,
     col = c("forestgreen"))

# Redraw borders
plot(wrld_simpl,
     add = TRUE,
     border = "dark grey")
box()
# Restore default margins
par(mar = c(5, 4, 4, 2) + 0.1)
# This creates a nicer map:
# plot(sdm@binary, legend = FALSE, col = c("#DEDEDE", "#228B22")) # Grey and forest green
dev.off()

# Save raster to files
suppressMessages(writeRaster(x = probabilities.raster, 
                             filename = paste0(outpath, outprefix, "-", sdm.algorithm, "-prediction.grd"),
                             format = "raster",
                             overwrite = TRUE))

suppressMessages(writeRaster(x = presence.raster, 
                             filename = paste0(outpath, outprefix, "-", sdm.algorithm, "-prediction-threshold.grd"),
                             format = "raster",
                             overwrite = TRUE))
cat("Finished with file writing.\n")

#MONTH PLOT GENERATION

for (i in unique(obs.data$month)) {
    dir.create(paste0(outpath, i))
}
