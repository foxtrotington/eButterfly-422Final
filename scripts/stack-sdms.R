# Stack SDM rasters into composity biodiversity map
# Jeff Oliver
# jcoliver@email.arizona.edu
# 2017-11-20

rm(list = ls())

################################################################################
# SETUP
# Gather path information
# Load dependancies
args = commandArgs(trailingOnly = TRUE)
usage.string <- "Usage: Rscript --vanilla scripts/stack-sdms.R <path/to/raster/files> <output-file-prefix> <path/to/output/directory/>"

# Make sure a readable file is first argument
if (length(args) < 1) {
  stop(paste("stack-sdms requires path to raster files", 
             usage.string,
             sep = "\n"))
}

raster.path <- args[1]
raster.files <- list.files(path = raster.path, pattern = ".grd$", full.names = TRUE)
if (length(raster.files) < 1) {
  stop(paste0("No raster files (.grd) found in path: ", raster.path))
}

if (length(args) < 2) {
  stop(paste("stack-sdms requires an output file prefix",
             usage.string,
             sep = "\n"))
}
outprefix <- args[2]

# Make sure the third argument is there for output directory
if (length(args) < 3) {
  stop(paste("stack-sdms requires an output directory",
             usage.string,
             sep = "\n"))
}
outpath <- args[3]

# Make sure the path ends with "/"
if (substring(text = outpath, first = nchar(outpath), last = nchar(outpath)) != "/") {
  outpath <- paste0(outpath, "/")
}

# Make sure directories are writable
required.writables <- c(outpath)
write.access <- file.access(names = required.writables)
if (any(write.access != 0)) {
  stop(paste0("You do not have sufficient write access to one or more directories. ",
              "The following directories do not appear writable: \n",
              paste(required.writables[write.access != 0], collapse = "\n")))
}
rm(required.writables, write.access)

required.packages <- c("rgdal", "raster", "maptools")
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
functions <- list.files(path = "functions", pattern = ".R", full.names = TRUE)
for(f in 1:length(functions)) {
  source(file = functions[f])
}
rm(f, functions)

################################################################################

stacked.SDMs <- StackSDMs(raster.files = raster.files)
xmin <- -165
xmax <- -52
ymin <- 15
ymax <- 75

# TODO: Take a look at a ggplot implementation:
# https://nrelscience.org/2013/05/30/this-is-how-i-did-it-mapping-in-r-with-ggplot2/

# Load in data for map borders
png.name <- paste0(outpath, outprefix, "-stack.png")
png(filename = png.name)
data(wrld_simpl)
plot(wrld_simpl, xlim = c(xmin, xmax), ylim = c(ymin, ymax), axes = TRUE, col = "gray95")
plot(stacked.SDMs, add = TRUE, col = rev(topo.colors(100)), legend = FALSE)
plot(wrld_simpl, xlim = c(xmin, xmax), ylim = c(ymin, ymax), add = TRUE, border = "gray10", col = NA)
box()
dev.off()

# Save raster to files
suppressMessages(writeRaster(x = stacked.SDMs, 
                             filename = paste0(outpath, outprefix, "-stack.grd"),
                             format = "raster",
                             overwrite = TRUE))
