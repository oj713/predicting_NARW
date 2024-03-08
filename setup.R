suppressPackageStartupMessages(
  {
    library(dplyr) # data transformation
    library(sf) # simple features -- storing and managing georeferences
    library(stars) # spatial data
    library(calanusthreshold) #calanus data
    library(brickman) # brickman data
    library(ncdf4) # querying data 
    library(tidymodels)
    library(yaml)
    library(purrr)
    library(gridExtra)
  })

### DATA HELPERS

# defining local function that will filter the data based on date 
filter_dates <- function(data, date_start, date_end) {
  if (!is.null(date_start)) {
    data <- filter(data, date >= as.Date(date_start))
  }
  if (!is.null(date_end)) {
    data <- filter(data, date <= as.Date(date_end))
  }
  data
}

### PREDICTION AND PLOT HELPERS

mon_names <- c("Jan", "Feb", "Mar", "Apr", "May", "Jun", 
               "Jul", "Aug", "Sep", "Oct", "Nov", "Dec")

# converts a month number to the corresponding string 
as_month <- function(mon_num = NA) {
  
  if (is.na(mon_num)) {return("")}
  
  paste("-", mon_names[mon_num])
}

# returns a list of monthly variables in Brickman dataset
mon_vars <- function() {
  c("Xbtm", "MLD", "Sbtm", "SSS", "SST", "Tbtm", "U", "V")
}

#' creates a data frame of all climate scenarios
#'
#' @param ... numerics, which climate scenarios should be retrieved
#'   if no argument is provided, all five scenarios are returned
#' @return a dataframe of all five climate scenarios
climate_table <- function(...) {
  y <- c(2055, 2075, 2055, 2075, NA)
  s <- c("RCP45", "RCP45", "RCP85", "RCP85", "PRESENT")
  
  data.frame(scenario = s, year = y) |>
    dplyr::slice(...) |>
    rowwise()
}

#' returns the file path to a desired climate prediction folder
#' 
#' @param v the version of the desired prediction
#' @param year the year of the desired prediction
#' @param scenario the scenario of the desired prediction
#' @param ... additional path specifiers
#' @return chr, the path to the desired prediction folder
pred_path <- function(v = "v1.00", 
                      year = c(2055, 2075)[1], 
                      scenario = c("RCP45", "RCP85", "PRESENT")[1],
                      ...) {
  #constructing path
  path <- file.path(v_path(v = v), "pred") 
  if (scenario != "PRESENT") {
    path <- file.path(path, year)
  }
  path <- file.path(path, scenario, ...)
  return(path)
}

### VERSION HELPERS

# Note: many functions here take heavy reference from Kenny's setup.R

#' Parse a version string into subparts
#' Versions have format vMajor.Minor
#' 
#' @param v version string to parse
#' @return named character vector of version subparts
parse_version <- function(v = "v1.00") {
  vsplit = strsplit(v, '.', fixed=TRUE) |> unlist()
  c(major = vsplit[1], minor = vsplit[2])
}

#' Constructs a file path to given version folder
#' 
#' @param v model version
#' @param ... additional path specifiers
#' @param root root path to project dir
#' @return file path to version folder
v_path <- function(v = "v1.00", ..., 
                   root = "/mnt/ecocast/projectdata/students/ojohnson/brickman/versions") {
  major <- parse_version(v)["major"]
  file.path(root, major, v, ...)
}

### YAML HELPERS

#' Reads the yaml configuration for the given version
#' 
#' @param v the desired version
#' @return list of configuration values
read_config <- function(v = "v1.00") {
  yaml::read_yaml(v_path(v = v, paste0(v, ".yaml")))
}


#' Writes the given configuration to file
#' 
#' @param config the configuration list
#' @param overwrite whether to allow overwrite of existing files
#' @return list of config values
write_config <- function(config, 
                         overwrite = FALSE) {
  v <- config$version
  path = v_path(v)
  if (!dir.exists(path)) {
    okay <- dir.create(file.path(path), recursive = TRUE)
  }
  yaml_file <- file.path(path, paste0(v, ".yaml"))
  if(overwrite == FALSE && file.exists(yaml_file)) {
    stop('configuration already exists:', version)
  }
  
  yaml::write_yaml(config, yaml_file)
  return(config)
}





