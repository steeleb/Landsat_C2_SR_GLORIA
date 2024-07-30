# Source functions for this {targets} list
tar_source("c_data_download_collation/src/")

# Download and process GEE output from GLORIA/Maciel pulls -------------

# this pipeline collates all of the GEE output files for the GLORIA locations
# and for the Maciel et al filtered/matched dataset.

# prep folder structure
suppressWarnings({
  dir.create("c_data_download_collation/in/")
  dir.create("c_data_download_collation/mid/")
  dir.create("c_data_download_collation/out/")
})

c_data_download_collation <- list(
  # check to see that all tasks are complete! This target will run until all
  # cued GEE tasks from the previous target are complete.
  tar_target(
    name = poi_tasks_complete,
    command = {
      eeRun
      source_python("c_data_download_collation/py/poi_wait_for_completion.py")
    },
    packages = "reticulate"
  ),
    
  # download the GLORIA data from Google Drive
  tar_target(
    name = c_download_GLORIA_files,
    command = {
      poi_tasks_complete
      download_csvs_from_drive(drive_folder_name = config_file$google_settings[[2]]$proj,
                                       google_email = config_file$google_settings[[1]]$google_email,
                                       version_identifier = config_file$google_settings[[5]]$run_date)
      },
    packages = c("tidyverse", "googledrive")
  ),
  
  tar_target(
    name = c_collated_GLORIA,
    command = collate_csvs_from_drive(file_prefix = config_file$google_settings[[2]]$proj, 
                                      version_identifier = config_file$google_settings[[5]]$run_date)
  ),
  
  # and collate the data with metadata
  tar_target(
    name = b_GLORIA_SR_metadata,
    command = {
      c_collated_GLORIA
      combine_metadata_with_pulls(file_prefix = config_file$google_settings[[2]]$proj,
                                  version_identifier = config_file$google_settings[[5]]$run_date,
                                  collation_identifier = "2024-07-30")
    },
    packages = c("tidyverse", "feather")
  )
  # check for dupes! Should be taken care of now
  #,
  # 
  # # pass the QAQC filter over each of the listed files, creating filtered files
  # tar_target(
  #   name = b_QAQC_filtered_data,
  #   command = baseline_QAQC_RS_data(filepath = b_collated_files),
  #   packages = c("tidyverse", "feather"),
  #   pattern = map(b_collated_files)
  # )
)