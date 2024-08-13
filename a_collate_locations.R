library(targets)
library(tarchetypes)


# Purpose of this {targets} group-------------------------------------------

# This script collates the locations from the upstream GLORIA dataset and the
# Maciel, et al matchups to replicate the analysis, but with corrections to the 
# surface reflectance data to better align sensor changes between missions.

## Collate locations

# To effectively collate the locations, we're going to use the upstream GLORIA 
# metadata, retaining only the GLORIA_ID and latitude/longitude columns and grab
# the unique locations from the Maciel dataset, flagging GLORIA overlap and adding
# any additional locations to the resulting location collation. CRS is not 
# specified for either dataset, so we assume WGS84

# Define {targets} workflow -----------------------------------------------

# Set target-specific options such as packages.
tar_option_set(packages = "tidyverse")

a_collate_locations <- list(
  # metadata processing ----
  
  #load/track gloria locs
  tar_file_read(
    name = gloria_metadata,
    command = "data/GLORIA_data/GLORIA_meta_and_lab.csv",
    read = read_csv(!!.x),
    packages = "readr"
  ),
  #load/track maciel matchups (these include insitu band data)
  tar_file_read(
    name = maciel_matches,
    command = "data/Maciel_data/Matchups.csv",
    read = read_csv(!!.x),
    packages = "readr"
  ),
  #format gloria data (no band data, just site data)
  tar_target(
    name = gloria_formatted,
    command = gloria_metadata %>% 
      select(GLORIA_ID, Latitude, Longitude, Water_body_type) %>% 
      distinct() %>% 
      # filter to inland sites (drop coastal ocean and other)
      # Water_body_type	Water body type (multiple choice list)
      # 1	Lake
      # 2	Estuary
      # 3	Coastal ocean
      # 4	River
      # 5	Other
      filter(Water_body_type %in% c(1,2,4))
  ),
  
  #format Maciel metadata for join
  tar_target(
    name = maciel_formatted,
    command = maciel_matches %>% 
      select(Maciel_ID = ID, 
             Latitude = lat, 
             Longitude = long) %>% 
      distinct() %>% 
      mutate(GLORIA_ID = if_else(grepl("\\bGID_", Maciel_ID),
                                 Maciel_ID,
                                 NA_character_),
             maciel = 1)
  ),
  
  #join those suckers, harmonize and drop locs without lat/lon
  tar_target(
    name = collated_IDS,
    command = full_join(gloria_formatted, maciel_formatted) %>% 
      mutate(ID = if_else(is.na(GLORIA_ID),
                          Maciel_ID,
                          GLORIA_ID)) %>% 
      select(ID, Latitude, Longitude) %>% 
      rowid_to_column() %>% 
      filter(!is.na(Latitude|Longitude))
  ),
  
  tar_target(
    name = unique_lat_lon,
    command = collated_IDS %>% 
      summarize(.by = c(Latitude, Longitude)) %>% 
      rowid_to_column("location_id") 
  ),

  # save the file for the pull
  tar_target(
    name = save_unique_locations,
    command = write_csv(unique_lat_lon, "data/unique_locations_for_pull.csv"),
  ),
  
  # and make a new target that has all the information in it for collation later
  tar_target(
    name = collated_IDS_w_locID,
    command = full_join(collated_IDS, unique_lat_lon)
  ),
  
  # gloria data and data processing ----
  tar_file_read(
    name = gloria_data_raw,
    command = "data/GLORIA_data/GLORIA_Rrs_mean.csv",
    read = read_csv(!!.x),
    packages = 'readr'
  ),
  tar_file_read(
    name = gloria_qc,
    command = "data/GLORIA_data/GLORIA_qc_flags.csv",
    read = read_csv(!!.x),
    packages = 'readr'
  ),
  tar_file_read(
    name = gloria_std,
    command = "data/GLORIA_data/GLORIA_Rrs_std.csv",
    read = read_csv(!!.x),
    packages = 'readr'
  ),
  tar_file_read(
    name = gloria_wq,
    command = "data/GLORIA_data/GLORIA_waterqual_uncert.csv",
    read = read_csv(!!.x),
    packages = 'readr'
  ),
  
  # and collate the files
  tar_target(
    name = gloria_db,
    command = reduce(list(gloria_data_raw, gloria_qc, gloria_std, gloria_wq),
                     full_join)
  )

)
  