# Source functions for this {targets} list
#tar_source("e_GLORIA_match/src/")

# Match up GLORIA database with SR pulls -------------

e_GLORIA_match <- list(
  tar_file_read(
    name = e_GLORIA_DSWE1_data,
    command = c_QAQC_filtered_data[grepl('_DSWE1_', c_QAQC_filtered_data)],
    read = read_feather(!!.x),
    packages = "feather"
  ),
  
  tar_target(
    name = GLORIA_rsr_date,
    command = {
      # format gloria data and join with relative spectral response
      gloria_metadata %>% 
        mutate(insitu_date = as_date(Date_Time_UTC)) %>% 
        filter(Water_body_type %in% c(1,2,4)) %>% 
        select(GLORIA_ID,
               Latitude, Longitude,
               insitu_date) %>% 
        left_join(., GLORIA_rsr_harmonize) %>% 
        rename(ID = GLORIA_ID) %>% 
        left_join(., collated_IDS_w_locID)
    }
  ),
  
  # join with Gloria metadata and filter to within 2 days of in situ measurement
  tar_target(
    name = e_info_data_matches,
    command = {
      full_join(e_GLORIA_DSWE1_data %>% 
                  mutate(location_id = as.numeric(rowid)) %>% 
                  select(-rowid), 
                GLORIA_rsr_date,
                relationship = "many-to-many") %>% 
        mutate(day_diff = insitu_date - date) %>% 
        filter(abs(day_diff) <= 2) %>% 
        arrange(abs(day_diff)) %>% 
        slice(1, .by = ID) %>% 
        select(-SWIR1_insitu)
    }
  ),
  
  tar_target(
    name = e_matches_light,
    command = {
      e_info_data_matches %>% 
      select(ID, date, day_diff, mission, 
             # surface reflectance 
             med_Aerosol, med_Blue:med_Nir, 
             # in situ
             CA_insitu, Blue_insitu, Red_insitu, Green_insitu, NIR_insitu)
    }
  )
)
  