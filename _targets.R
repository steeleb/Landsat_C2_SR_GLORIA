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

# Define {targets} workflow -----------------------------------------------

# Set target-specific options such as packages.
tar_option_set(packages = "tidyverse")

tar_source(files = c(
  "b_data_acquisition.R",
  "c_data_download_collation.R"
  ))

# target objects in workflow
list(
  b_data_acquisition,
  c_data_download_collation
)
