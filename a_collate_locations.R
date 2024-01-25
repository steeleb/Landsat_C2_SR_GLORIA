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
  #load/track gloria locs
  tar_file_read(
    name = gloria_metadata,
    command = "data/GLORIA_meta_and_lab.csv",
    read = read_csv(!!.x),
    packages = "readr"
  ),
  #load/track maciel matchups
  tar_file_read(
    name = maciel_matches,
    command = "data/Matchups.csv",
    read = read_csv(!!.x),
    packages = "readr"
  ),
  #format gloria data
  tar_target(
    name = gloria_formatted,
    command = gloria_metadata %>% 
      select(GLORIA_ID, Latitude, Longitude) %>% 
      distinct()
  ),
  #format maciel data
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
    name = collated_locs,
    command = full_join(gloria_formatted, maciel_formatted) %>% 
      mutate(ID = if_else(is.na(GLORIA_ID),
                          Maciel_ID,
                          GLORIA_ID)) %>% 
      select(ID, Latitude, Longitude) %>% 
      rowid_to_column() %>% 
      filter(!is.na(Latitude|Longitude))
  ),
  # save the file
  tar_target(
    name = save_collated_locs,
    command = write_csv(collated_locs, "data/collated_locations_for_pull.csv"),
    packages = "readr"
  )
)
  