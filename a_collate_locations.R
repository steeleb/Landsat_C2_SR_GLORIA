library(targets)
library(tarchetypes)

# Define {targets} workflow -----------------------------------------------

# Set target-specific options such as packages.
tar_option_set(packages = "tidyverse")

a_collate_locations <- list(
  # read and track the config file
  tar_file_read(
    name = gloria_metadata,
    command = "data/GLORIA_meta_and_lab.csv",
    read = read_csv(!!.x),
    packages = "readr"
  ),
  tar_file_read(
    name = maciel_matches,
    command = "data/Matchups.csv",
    read = read_csv(!!.x),
    packages = "readr"
  ),
  tar_target(
    name = gloria_formatted,
    command = gloria_metadata %>% 
      select(GLORIA_ID, Latitude, Longitude) %>% 
      distinct()
  ),
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
  tar_target(
    name = save_collated_locs,
    command = write_csv(collated_locs, "data/collated_locations_for_pull.csv"),
    packages = "readr"
  )
)
  