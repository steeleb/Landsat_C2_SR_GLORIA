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
  tar_source("b_data_acquisition/pySetup.R")
} else {
  use_condaenv(file.path(getwd(), "env"))
}

# Define {targets} workflow -----------------------------------------------

# Set target-specific options such as packages.
tar_option_set(packages = "tidyverse")

tar_source(files = c(
  "a_collate_locations.R",
  "b_data_acquisition.R",
  "c_data_download_collation.R",
  "c_data_download_collation_nomask.R",
  "d_calculate_band_values.R",
  "d_GLORIA_match.R"
  ))

# target objects in workflow
list(
  a_collate_locations,
  b_data_acquisition,
  c_data_download_collation,
  c_data_download_collation_nomask,
  d_calculate_band_values,
  d_GLORIA_match
)
