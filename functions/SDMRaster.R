# Functions for running species distribution models
# Jeffrey C. Oliver
# jcoliver@email.arizona.edu
# 2017-11-08

################################################################################
#' Finds minimum and maximum latitude and longitude
#' 
#' @param x a data.frame or list of data.frames
MinMaxCoordinates <- function(x) {
  # If passed a single data.frame, wrap in a list
  if(class(x) == "data.frame") {
    x <- list(x)
  }
  
  # Establish starting min/max values
  max.lat <- -90
  min.lat <- 90
  max.lon <- -180
  min.lon <- 180

  # Iterate over all elements of list x and find min/max values
  for (i in 1:length(x)) {
    max.lat = ceiling(max(x[[i]]$lat, max.lat))
    min.lat = floor(min(x[[i]]$lat, min.lat))
    max.lon = ceiling(max(x[[i]]$lon, max.lon))
    min.lon = floor(min(x[[i]]$lon, min.lon))
  }
  
  # Format results and return
  min.max.coords <- c(min.lon, max.lon, min.lat, max.lat)
  names(min.max.coords) <- c("min.lon", "max.lon", "min.lat", "max.lat")
  return(min.max.coords)
}

################################################################################
#' Run species distribution model and return model and threshold
#' 
#' @param data data.frame with "lon" and "lat" values
SDMBioclim <- function(data, bg.replicates = 10) {
  ########################################
  # SETUP
  # Load dependancies
  # Prepare data
  
  # Load dependancies
  if (!require("raster")) {
    stop("SDMBioclim requires raster package, but package is missing.")
  }
  if (!require("dismo")) {
    stop("SDMBioclim requires dismo package, but package is missing.")
  }
  
  # Prepare data
  # Determine minimum and maximum values of latitude and longitude
  min.max <- MinMaxCoordinates(x = data)
  geographic.extent <- extent(x = min.max)
  
  # Get the biolim data
  bioclim.data <- getData(name = "worldclim",
                          var = "bio",
                          res = 2.5, # Could try for better resolution, 0.5, but would then need to provide lat & long...
                          path = "data/")
  bioclim.data <- crop(x = bioclim.data, y = geographic.extent)
  
  # Create pseudo-absence points (making them up, using 'background' approach)
  # raster.files <- list.files(path = paste0(system.file(package = "dismo"), "/ex"),
  #                            pattern = "grd", full.names = TRUE)
  # mask <- raster(raster.files[1])
  bil.files <- list.files(path = "data/wc2-5/", 
                          pattern = "*.bil$", 
                          full.names = TRUE)
  mask <- raster(bil.files[1])

  # Presence points
  presence.values <- extract(x = bioclim.data, y = data)

  probability.raster <- NA
  presence.raster <- NA
  
  for (rep in 1:bg.replicates) {
    # Random points for background (same number as our observed points)
    background.points <- randomPoints(mask = mask, n = nrow(data), ext = geographic.extent, extf = 1.25)
    colnames(background.points) <- c("lon", "lat")
    
    # Background, "pseudo-absence" points
    absence.values <- extract(x = bioclim.data, y = background.points)
    
    ########################################
    # ANALYSIS
    # Divide data into testing and training
    # Generate species distribution model
    
    # Divide data into testing and training
    group.presence <- kfold(data, 5)
    testing.group <- 1
    presence.train <- data[group.presence != testing.group, ]
    presence.test <- data[group.presence == testing.group, ]
    group.background <- kfold(background.points, 5)
    background.train <- background.points[group.background != testing.group, ]
    background.test <- background.points[group.background == testing.group, ]
    
    # Generate species distribution model
    sdm.model <- bioclim(x = bioclim.data, p = presence.train)
    # Evaluate performance so we can determine predicted presence 
    # threshold cutoff
    sdm.model.eval <- evaluate(p = presence.test, 
                               a = background.test, 
                               model = sdm.model, 
                               x = bioclim.data)
    sdm.model.threshold <- threshold(x = sdm.model.eval, 
                                     stat = "spec_sens")

    # Predict presence probability from model and bioclim data
    predict.presence <- predict(x = bioclim.data, 
                                object = sdm.model, 
                                ext = geographic.extent, 
                                progress = "")
    present <- predict.presence > sdm.model.threshold
    
    if (rep == 1) {
      probability.raster <- predict.presence
      presence.raster <- present
    } else {
      probability.raster <- mosaic(x = probability.raster, y = predict.presence, fun = sum)
      presence.raster <- mosaic(x = presence.raster, y = present, fun = sum)
    }
  }
  
  probability.raster <- probability.raster/bg.replicates
  return(list(probabilities = probability.raster, presence = presence.raster))
}

################################################################################
#' Run species distribution model for specific algorithm
#' 
#' @param data data.frame with "lon" and "lat" values
#' @param env.data Raster* object of predictor variables
#' @param sdm.algorithm character indicating algorithm to use (either "CTA", 
#' "RF", or "GLM")
#' @param bg.replicates integer number of replicates to run
SDMAlgos <- function(data, env.data, sdm.algorithm = "CTA", bg.replicates = 10) {
  # SSDM require
  
  probability.raster <- NA
  presence.raster <- NA
  
  for (rep in 1:bg.replicates) {
    sdm <- modelling(algorithm = sdm.algorithm, 
                     Occurrences = obs.data, 
                     Env = bioclim.data,
                     Xcol = "longitude",
                     Ycol = "latitude")
    
    if (rep == 1) {
      probability.raster <- sdm@projection
      presence.raster <- sdm@binary
    } else {
      probability.raster <- mosaic(x = probability.raster, y = sdm@projection, fun = sum, na.rm = TRUE)
      presence.raster <- mosaic(x = presence.raster, y = sdm@binary, fun = sum, na.rm = TRUE)
    }
  }
  
  probability.raster <- probability.raster/bg.replicates
  return(list(probabilities = probability.raster, presence = presence.raster))
}

################################################################################
#' Combine raster files to single layer
#' 
StackSDMs <- function(raster.files) {
  if (!require("raster")){
    stop("StackSDMs requires raster package, but package is missing")
  }
  if (!require("maptools")){
    stop("StackSDMs requires maptools package, but package is missing")
  }

  raster.mosaic <- raster(x = raster.files[1])
  raster.mosaic[raster.mosaic <= 0] <- NA

  if (length(raster.files) > 1) {
    for (f in 2:length(raster.files)) {
      raster.2 <- raster(x = raster.files[f])
      raster.2[raster.2 <= 0] <- NA
      xmin <- min(extent(raster.mosaic)[1], extent(raster.2)[1])
      xmax <- max(extent(raster.mosaic)[2], extent(raster.2)[2])
      ymin <- min(extent(raster.mosaic)[3], extent(raster.2)[3])
      ymax <- max(extent(raster.mosaic)[4], extent(raster.2)[4])
      raster.mosaic <- mosaic(x = raster.mosaic, y = raster.2, fun = sum)
      raster.mosaic[raster.mosaic <= 0] <- NA
    }
  }
  return(raster.mosaic)
}