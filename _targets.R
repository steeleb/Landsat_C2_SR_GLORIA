library(targets)
library(tarchetypes)
library(reticulate)

yaml_file <- "gloria_config.yml"

# MUST READ ---------------------------------------------------------------

# IMPORTANT NOTE:
#
# you must execute the command 'earthengine authenticate' in a zsh terminal
# before initializing this workflow. See the repository README for complete
# dependencies and troubleshooting.

# RUNNING {TARGETS}:
#
# use the file 'run_targets.Rmd', which includes EE authentication.


# Set up python virtual environment ---------------------------------------

if (!dir.exists("env")) {
  tar_source("data_acquisition/src/pySetup.R")
} else {
  use_condaenv(file.path(getwd(), "env"))
}


# Source functions --------------------------------------------------------

tar_source("data_acquisition/src/general_functions.R")
source_python("data_acquisition/src/gee_functions.py")


# Define {targets} workflow -----------------------------------------------

# Set target-specific options such as packages.
tar_option_set(packages = "tidyverse")

# target objects in workflow
list(
  # read and track the config file
  tar_file_read(
    name = config_file,
    command = yaml_file,
    read = read_yaml(!!.x),
    packages = 'yaml'
  ),
  
  # load, format, save yml as a csv
  tar_target(
    name = yml_save,
    command = {
      # make sure that {targets} runs the config_file target before this target
      config_file 
      format_yaml(yaml_file)
    },
    packages = c("yaml", "tidyverse") #for some reason, you have to load TV.
  ),
  
  # read in and track the formatted yml .csv file
  tar_file_read(
    name = yml,
    command = yml_save,
    read = read_csv(!!.x),
    packages = "readr"
  ),
  
  # load, format, save user locations as an updated csv called locs.csv
  tar_target(
    name = locs_save,
    command = grab_locs(yml),
    packages = "readr"
  ),
  
  # read and track formatted locations shapefile
  tar_file_read(
    name = locs,
    command = locs_save,
    read = read_csv(!!.x),
    packages = "readr"
  ),
  
  # get WRS tile acquisition method from yaml
  tar_target(
    name = WRS_detection_method,
    command = {
      locs
      get_WRS_detection(yml) # locs only
    },
    packages = "readr"
  ),
  
  # get WRS tiles
  tar_target(
    name = WRS_tiles,
    command = get_WRS_tiles(WRS_detection_method, yml, locs),
    packages = c("readr", "sf")
  ),
  
  # run the Landsat pull as function per tile
  tar_target(
    name = eeRun,
    command = {
      yml
      locs
      csv_to_eeFeat
      apply_scale_factors
      #square_buff
      DSWE
      Mbsrv
      Ndvi
      Mbsrn
      Mndwi
      Awesh
      add_rad_mask
      sr_cloud_mask
      sr_aerosol
      cf_mask
      calc_hill_shadows
      calc_hill_shades
      remove_geo
      maximum_no_of_tasks
      ref_pull_457_DSWE1
      ref_pull_89_DSWE1
      run_GEE_per_tile(WRS_tiles)
    },
    pattern = map(WRS_tiles),
    packages = "reticulate"
  )
)
