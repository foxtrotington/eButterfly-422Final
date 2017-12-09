# Prepare data from file for SDM
# Jeffrey C. Oliver
# jcoliver@email.arizona.edu
# 2017-11-08

################################################################################
#' Read in data from files
#' 
#' Makes sure files exist and are readable, then reads them into 
#' data frame. Checks for columns "latitude" and "longitude" and 
#' renames them "lat" and "lon", respectively. Removes duplicate 
#' rows.
#' 
#' @param file character vector of length one with file name
#' @param sep separator character, defaults to ","
PrepareData <- function(file, sep = ",") {
  # Make sure the input files exist
  if (!file.exists(file)) {
    stop(paste0("Cannot find input data file ", infile, ", file does not exist.\n"))
  }
  
  # Make sure the input files are readable
  if (file.access(names = file, mode = 4) != 0) {
    stop(paste0("You do not have sufficient access to read ", file, "\n"))
  }
  
  # Read data into data.frame
  original.data <- read.csv(file = file,
                            stringsAsFactors = FALSE,
                            sep = sep)
  
  # Make sure coordinate columns are in data
  if (!(any(colnames(original.data) == "longitude") 
        && any(colnames(original.data) == "latitude"))) {
    stop(paste0("Missing required column(s) in ", file, "; input file must have 'latitude' and 'longitude' columns.\n"))
  }
  
  # Extract only those columns of interest and rename them for use with 
  # dismo package tools
  coordinate.data <- original.data[, c("longitude", "latitude")]
  colnames(coordinate.data) <- c("lon", "lat")
  
  # Remove duplicate rows
  duplicate.rows <- duplicated(x = coordinate.data)
  coordinate.data <- coordinate.data[!duplicate.rows, ]
  coordinate.data <- na.omit(coordinate.data)
  
  return(coordinate.data)
}
