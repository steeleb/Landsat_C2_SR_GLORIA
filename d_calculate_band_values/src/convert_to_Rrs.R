convert_to_Rrs <- function(response_func, mission_id, raw_data, id) {
  
  # filter response function for mission of interest
  rsr <- response_func %>% 
    filter(mission == mission_id)
  
  # get band names to map over
  band_names <- names(rsr)[grepl("band", names(rsr))]
  
  # calculate factor of correction (FAC)
  FAC <- map(band_names,
             function(band) {
               total <- sum(rsr[[band]], na.rm = TRUE)
               rsr[[band]] <- rsr[[band]] / total
               rsr %>% 
                 select(wavelength, !!sym(band))
             }) %>% 
    reduce(full_join, by = "wavelength")
  
  # pivot raw data for vertical application of FACs
  data <- raw_data %>% 
    select({{ id }}, starts_with("Rrs_mean")) %>% 
    pivot_longer(cols = starts_with("Rrs_mean"),
                 names_to = "wavelength", values_to = "value") %>% 
    mutate(wavelength = as.numeric(str_remove(wavelength, "Rrs_mean_"))) %>% 
    left_join(FAC, by = "wavelength")
  
  # calculate the rsr contribution of each wavelength for each band according 
  # to the response function
  data_w_fac <- map(band_names,
                    function(band) {
                      data %>% 
                        mutate(!!sym(band) := !!sym(band) * value) %>%
                        select({{ id }}, wavelength, !!sym(band))
                    }) %>% 
    reduce(., full_join) %>% 
    # drop any columns that don't have data
    select(where(~!all(is.na(.))))
  
  # get the band names from the new dataset that has dropped null columns
  complete_bands <- names(data_w_fac)[grepl("band", names(data_w_fac))]
  # summarize to calculate the relative spectral response for each mission band
  data_rsr <- map(complete_bands, 
                      function(band) {
                        data_w_fac %>% 
                          summarize(!!sym(band) := sum(!!sym(band), na.rm = TRUE), 
                                    .by = {{ id }})
                      }) %>% 
    reduce(., full_join)
  
  # return the dataframe with the updated band names (to account for mission)
  data_rsr %>% 
    mutate(mission = mission_id)
}