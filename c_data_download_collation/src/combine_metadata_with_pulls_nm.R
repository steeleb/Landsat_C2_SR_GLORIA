#' @title Add scene metadata to RS band summary data
#' 
#' @description
#' Function to combine a reduced set of scene metadata with the upstream collated RS
#' data for downstream use
#'
#' @param file_prefix specified string that matches the file group to collate
#' @param version_identifier user-specified string to identify the RS pull these
#' data are associated with
#' @param collation_identifier user-specified string to identify the output of this
#' target
#' @returns silently creates collated .feather files from 'mid' folder and 
#' dumps into 'out'
#' 
#' 
combine_metadata_with_pulls_nm <- function(file_prefix, version_identifier, collation_identifier) {
  files <- list.files(file.path("c_data_download_collation/mid/"),
                     pattern = file_prefix,
                     full.names = TRUE) %>% 
    # and grab the right version
    .[grepl(version_identifier, .)]
  
  # load the metadata - use the metadata collation from the masked run, since they are the same
  metadata <- read_feather('c_data_download_collation/mid/SR_GLORIA_collated_metadata_2024-07-30.feather')
  # do some metadata formatting
  metadata_light <- metadata %>% 
    # Landsat 4-7 and 8/9 store image quality differently, so here, we"re harmonizing this.
    mutate(IMAGE_QUALITY = if_else(is.na(IMAGE_QUALITY), 
                                   IMAGE_QUALITY_OLI, 
                                   IMAGE_QUALITY)) %>% 
    rename(system.index = `system:index`) %>% 
    select(system.index, 
           WRS_PATH, 
           WRS_ROW, 
           "mission" = SPACECRAFT_ID, 
           "date" = DATE_ACQUIRED, 
           "UTC_time" = SCENE_CENTER_TIME, 
           CLOUD_COVER,
           IMAGE_QUALITY, 
           IMAGE_QUALITY_TIRS, 
           SUN_AZIMUTH, 
           SUN_ELEVATION) 
  
  # check for point files and collate with metadata
  if (any(grepl("point", files))) {
    point_file <- files[grepl("point", files)]
    points <- read_feather(point_file)
    # format system index for join - right now it has a rowid and the unique LS id
    # could also do this rowwise, but this method is a little faster
    points$rowid <- map_chr(.x = points$`system:index`, 
                            function(.x) {
                              parsed <- str_split(.x, '_')
                              str_len <- length(unlist(parsed))
                              unlist(parsed)[str_len]
                            })
    points$system.index <- map_chr(.x = points$`system:index`, 
                                   #function to grab the system index
                                   function(.x) {
                                     parsed <- str_split(.x, '_')
                                     str_len <- length(unlist(parsed))
                                     parsed_sub <- unlist(parsed)[1:(str_len-1)]
                                     str_flatten(parsed_sub, collapse = '_')
                                     })
    points <- points %>% 
      select(-`system:index`) %>% 
      left_join(., metadata_light) %>% 
      mutate(DSWE = str_split(source, "_")[[1]][7], .by = source)
    
    # break out the DSWE 1 data
    if (nrow(points %>% filter(DSWE == 'DSWE1')) > 0) {
      DSWE1_points <- points %>%
        filter(DSWE == 'DSWE1')
      write_feather(DSWE1_points,
                    file.path("c_data_download_collation_nomask/out/",
                              paste0(file_prefix,
                                     "_collated_DSWE1_points_meta_v",
                                     collation_identifier,
                                     ".feather")))
    } 
    
    # and the DSWE 1a data
    if (nrow(points %>% filter(DSWE == 'DSWE1a')) > 0) {
      DSWE1a_points <- points %>%
        filter(DSWE == 'DSWE1a')
      write_feather(DSWE1a_points,
                    file.path("c_data_download_collation_nomask/out/",
                              paste0(file_prefix,
                                     "_collated_DSWE1a_points_meta_v",
                                     collation_identifier,
                                     ".feather")))
    }
    # and the DSWE 3 data
    if (nrow(points %>% filter(DSWE == 'DSWE3')) > 0) {
      DSWE3_points <- points %>%
        filter(DSWE == 'DSWE3')
      write_feather(DSWE3_points,
                    file.path("c_data_download_collation_nomask/out/",
                              paste0(file_prefix,
                                     "_collated_DSWE3_points_meta_v",
                                     collation_identifier,
                                     ".feather")))
    }
  }
  # return the list of files from this process
  list.files("c_data_download_collation_nomask/out/",
             pattern = file_prefix,
             full.names = TRUE) %>% 
    #but make sure they are the specified version
    .[grepl(collation_identifier, .)] %>% 
    .[!grepl('filtered', .)]
  
}
