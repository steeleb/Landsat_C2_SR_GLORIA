library(targets)
library(tarchetypes)
library(reticulate)

yaml_file <- "gloria_config.yml"

# Set up python virtual environment ---------------------------------------

tar_source("b_data_acquisition/pySetup.R")


# Source functions --------------------------------------------------------

tar_source("b_data_acquisition/src/")
source_python("b_data_acquisition/py/gee_functions.py")
source_python("b_data_acquisition/py/gee_functions_no_masks.py")


# Define {targets} workflow -----------------------------------------------

# Set target-specific options such as packages.
tar_option_set(packages = "tidyverse")

b_data_acquisition <- list(
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
      save_unique_locations
      collated_IDS_w_locID
      config_file 
      # and that the locs file has been created
      # save_collated_locs # except that this is making the pipeline become outdated
      # so just run this as was before
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
    packages = "tidyverse"
  ),
  
  # read and track formatted locations shapefile
  tar_file_read(
    name = locs,
    command = locs_save,
    read = read_csv(!!.x),
    packages = "readr"
  ),
  
  tar_target(
    name = WRS_tiles,
    command = get_WRS_tiles(detection_method = "site", 
                            yaml = yml, 
                            locs = locs),
    packages = c("tidyverse", "sf")
  ),
  
  # run the Landsat pull as function per tile
  tar_target(
    name = eeRun,
    command = {
      yml
      locs
      run_GEE_per_tile(WRS_tile = WRS_tiles)
    },
    pattern = map(WRS_tiles),
    packages = "reticulate"
  ),
  
  # run the Landsat pull as function per tile
  tar_target(
    name = eeRun_no_mask,
    command = {
      yml
      locs
      run_GEE_per_tile_nomask(WRS_tile = WRS_tiles)
    },
    pattern = map(WRS_tiles),
    packages = "reticulate"
  )
  
)
