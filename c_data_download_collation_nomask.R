# Source functions for this {targets} list
tar_source("c_data_download_collation/src/")

# Download and process GEE output from GLORIA/Maciel pulls -------------

# this pipeline collates all of the GEE output files for the GLORIA locations
# and for the Maciel et al filtered/matched dataset.

# prep folder structure
suppressWarnings({
  dir.create("c_data_download_collation_nomask/in/")
  dir.create("c_data_download_collation_nomask/mid/")
  dir.create("c_data_download_collation_nomask/out/")
})

c_data_download_collation_nomask <- list(
  # check to see that all tasks are complete! This target will run until all
  # cued GEE tasks from the previous target are complete.
  tar_target(
    name = poi_tasks_complete_nomask,
    command = {
      poi_tasks_complete
      eeRun_no_mask
      source_python("c_data_download_collation/py/poi_wait_for_completion.py")
    },
    packages = "reticulate"
  ),
  
  # download the GLORIA data from Google Drive
  tar_target(
    name = c_download_GLORIA_nm_files,
    command = {
      poi_tasks_complete_nomask
      download_csvs_from_drive_nm(drive_folder_name = "SR_GLORIA_no_mask",
                                  google_email = yml$google_email,
                                  version_identifier = yml$run_date)
    },
    packages = c("tidyverse", "googledrive")
  ),
  
  tar_target(
    name = c_collated_GLORIA_nomask,
    command = {
      c_download_GLORIA_nm_files
      collate_csvs_from_drive_nm(file_prefix = yml$proj, 
                                 version_identifier = yml$run_date)
    },
    packages = c('tidyverse', 'feather')
  ),
  
  # and collate the data with metadata
  tar_target(
    name = c_GLORIA_SR_metadata_nomask,
    command = {
      c_collated_GLORIA_nomask
      combine_metadata_with_pulls_nm(file_prefix = yml$proj,
                                     version_identifier = yml$run_date,
                                     collation_identifier = "2024-07-30")
    },
    packages = c("tidyverse", "feather")
  ),
  
  # pass the QAQC filter over each of the listed files, creating filtered files
  tar_target(
    name = c_QAQC_filtered_data_nm,
    command = baseline_QAQC_RS_data_nm(filepath = c_GLORIA_SR_metadata_nomask,
                                       file_prefix = yml$proj,
                                       collation_identifier = "2024-07-30"),
    packages = c("tidyverse", "feather"),
    pattern = map(c_GLORIA_SR_metadata_nomask)
  )
)