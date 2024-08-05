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
           prop_clouds == 0) %>% # must be no clouds
    filter(if_all(c(med_Red, med_Green, med_Blue, med_Nir, med_Swir1, med_Swir2),
                  ~ (. < 0.5))) 

  
  fn = paste0(file_prefix, 
                    "_filtered_",
                    DSWE, "_nomask_",
                    type, "_v",
                    file_suffix,
                    ".feather")
  
  write_feather(df, file.path("c_data_download_collation_nomask/out/",
                              fn))
  
  # return the file name
  file.path("c_data_download_collation_nomask/out/",
            fn)
}
