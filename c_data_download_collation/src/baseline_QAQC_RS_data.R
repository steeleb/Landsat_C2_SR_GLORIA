#' @title First-pass QAQC of RS feather file
#' 
#' @description
#' Function to make first-pass QAQC of the DSWE1 RS data to remove any rows where the
#' image quality is below 7 (out of 10), where the dswe1 count is less than 10, 
#' where the proportion of clouds in the buffer area are greater than 25%, 
#' or  where any of the band summaries are beyond likely range (> 0.5Rrs). Additionally,
#' this function flags and recodes thermal data if it has high uncertainty and/or
#' seems egregiously errant.
#'
#' @param filepath filepath of a collated .feather file output from the 
#' function "combine_metadata_with_pulls.R"
#' @param file_prefix specified string that matches the file group to collate
#' @param collation_identifier user-specified string to identify the collation version
#' @returns silently creates filtered .feather file from collated files in out 
#' folder and dumps filtered into out folder
#' 
#' 
baseline_QAQC_RS_data <- function(filepath, file_prefix, collation_identifier) {
  
  collated <- read_feather(filepath)
  
  #get some info for saving the file
  filename <- str_split(filepath, "/")[[1]][4]
  file_prefix <- file_prefix
  file_suffix <- collation_identifier
  DSWE <- collated$DSWE[1]
  type <- case_when(grepl("point", filepath) ~ "point",
                    grepl("poly", filepath) ~ "poly",
                    grepl("center", filepath) ~ "center")
  pcount_colname = sym(paste0("pCount_", tolower(DSWE)))
  # do the actual QAQC pass and save the filtered file
  df <- collated %>%
    filter(IMAGE_QUALITY >= 7, 
           !!pcount_colname >= 10, 
           prop_clouds < 0.25) %>% # proportion of clouds in buffer < 25%
    filter(if_all(c(med_Red, med_Green, med_Blue, med_Nir, med_Swir1, med_Swir2),
                  ~ (. < 0.5))) %>% 
    ## aggressive thermal band cleaning
    # recode where any clouds in aoi
    mutate(SurfaceTemp_flag = if_else(prop_clouds != 0,
                                      1,
                                      0),
           across(c(med_SurfaceTemp, min_SurfaceTemp, mean_SurfaceTemp, sd_SurfaceTemp, med_temp_qa, kurt_SurfaceTemp),
                  ~ if_else(prop_clouds != 0,
                            NA_real_,
                            .))) %>% 
    # recode where the ominous 150.0015 temperature is and flag
    mutate(SurfaceTemp_flag = if_else(min_SurfaceTemp < 151,
                                      2,
                                      SurfaceTemp_flag),
           across(c(med_SurfaceTemp, min_SurfaceTemp, mean_SurfaceTemp, sd_SurfaceTemp, med_temp_qa, kurt_SurfaceTemp),
                  ~ if_else(min_SurfaceTemp < 151,
                            NA_real_,
                            .))) %>% 
    # recode where temps less than 270 (-2 C) and flag 
    mutate(SurfaceTemp_flag = if_else(min_SurfaceTemp < 270,
                                      3, 
                                      SurfaceTemp_flag),
           across(c(med_SurfaceTemp, min_SurfaceTemp, mean_SurfaceTemp, sd_SurfaceTemp, med_temp_qa, kurt_SurfaceTemp),
                  ~ if_else(min_SurfaceTemp < 270,
                            NA_real_,
                            .))) %>% 
    # recode where median temp uncertainty is greater than 5 deg and flag
    mutate(SurfaceTemp_flag = if_else(med_temp_qa*0.01 > 5,
                                      4,
                                      SurfaceTemp_flag),
           across(c(med_SurfaceTemp, min_SurfaceTemp, mean_SurfaceTemp, sd_SurfaceTemp, med_temp_qa, kurt_SurfaceTemp),
                  ~ if_else(med_temp_qa*0.01 > 5,
                            NA_real_,
                            .))) %>% 
    # recode where standard deviation of the mean is greater than 5 deg and flag
    mutate(SurfaceTemp_flag = if_else(sd_SurfaceTemp > 5,
                                      5,
                                      SurfaceTemp_flag),
           across(c(med_SurfaceTemp, min_SurfaceTemp, mean_SurfaceTemp, sd_SurfaceTemp, med_temp_qa, kurt_SurfaceTemp),
                  ~ if_else(sd_SurfaceTemp > 5,
                            NA_real_,
                            .))) %>% 
    # recode where any temp is greater than 40 C (312.15) and flag
    mutate(SurfaceTemp_flag = if_else(if_any(c(med_SurfaceTemp, mean_SurfaceTemp, med_SurfaceTemp),
                                             ~ . > 312.15),
                                      6,
                                      SurfaceTemp_flag),
           across(c(med_SurfaceTemp, min_SurfaceTemp, mean_SurfaceTemp, sd_SurfaceTemp, med_temp_qa, kurt_SurfaceTemp),
                  ~ if_else(if_any(c(med_SurfaceTemp, mean_SurfaceTemp, med_SurfaceTemp),
                                   ~ . > 312.15),
                            NA_real_,
                            .))) 
  
  write_feather(df, file.path("c_data_download_collation/out/",
                              paste0(file_prefix, 
                                     "_filtered_",
                                     DSWE, "_",
                                     type, "_v",
                                     file_suffix,
                                     ".feather")))
  
  # return the list of files from this process
  list.files("c_data_download_collation/out/",
             pattern = file_prefix,
             full.names = TRUE) %>% 
    #but make sure they are the specified version
    .[grepl(collation_identifier, .)] %>% 
    .[grepl('filtered', .)]
  
}
