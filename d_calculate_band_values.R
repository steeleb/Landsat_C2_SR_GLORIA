library(targets)
library(tarchetypes)

tar_source("d_calculate_band_values/src/")

# Purpose of this {targets} group-------------------------------------------


# Define {targets} workflow -----------------------------------------------

tar_option_set(packages = "tidyverse")

d_calculate_band_values <- list(
  # list the missions to convert hyperspectral to
  tar_target(
    name = missions,
    command = c("L5", "L7", "L8", "L9")
  ),
  
  # read in and collate the response functions ----
  
  # point to file names
  tar_target(
    name = response_function_files,
    command = c("data/NASA_RSR/L5_TM_RSR.xlsx",
                "data/NASA_RSR/L7_ETM_RSR.xlsx",
                "data/NASA_RSR/L8_OLI_RSR.xlsx",
                "data/NASA_RSR/L9_OLI2_RSR.xlsx")
  ),
  
  # map over them to 
  tar_target(
    name = response_functions,
    command = compile_rsr(rsr_path = response_function_files,
                          mission_id = missions),
    packages = c("tidyverse", "readxl", "janitor"),
    pattern = map(response_function_files, missions)
  ),

  # apply the RSR to GLORIA for each mission
  tar_target(
    name = GLORIA_rsr,
    command = convert_to_Rrs(response_func = response_functions,
                             mission = missions,
                             raw_data = gloria_db,
                             id = "GLORIA_ID") %>% 
      left_join(gloria_qc),
    pattern = missions
  )
  
)
  