# Source functions for this {targets} list
#tar_source("d_GLORIA_match/src/")

# Match up GLORIA database with SR pulls -------------

d_GLORIA_match <- list(
  tar_file_read(
    name = d_GLORIA_DSWE1_data,
    command = c_QAQC_filtered_data[grepl('_DSWE1_', c_QAQC_filtered_data)],
    read = read_feather(!!.x),
    packages = "feather"
  ),
  
  tar_target(
    name = d_overmatch,
    command = {
      # grab novel maciel data
      maciel <- maciel_matches %>% 
        mutate(insitu_date = mdy(Date)) %>% 
        filter(!grepl('\\bGID', ID)) %>% 
        select(ID, insitu_date, Latitude = lat, Longitude = long)
      # format gloria data
      gloria <- gloria_metadata %>% 
        mutate(insitu_date = as_date(Date_Time_UTC)) %>% 
        select(ID = GLORIA_ID, 
               insitu_date,
               Latitude, 
               Longitude)
      full_join(maciel, gloria) %>% 
        left_join(., collated_locs) %>% 
        filter(!is.na(rowid))
    }
  ),
  
  # join with Gloria metadata and filter to within 7 days of in situ measurement
  tar_target(
    name = d_info_data_matches,
    command = {
      left_join(d_GLORIA_DSWE1_data %>% mutate(rowid = as.numeric(rowid)), 
                d_insitu_dates,
                relationship = "many-to-many") %>% 
        mutate(day_diff = insitu_date - date) %>% 
        filter(abs(day_diff) <= 2) %>% 
        arrange(abs(day_diff)) %>% 
        group_by(ID) %>% 
        slice(1) %>% 
        left_join(., maciel_matches)
    }
  ),
  
  tar_target(
    name = d_matches_light,
    command = {
      d_info_data_matches %>% 
      select(ID, date, day_diff,
             # surface reflectance 
             med_Aerosol, med_Blue:med_Swir2, 
             # in situ
             CA_insitu:NIR_insitu, 
             # maciel pull
             CA_satellite:NIR_satellite)
    }
  )
)
  