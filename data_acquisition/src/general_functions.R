#' Function to read in yaml, reformat and pivot for easy use in scripts
#' 
#' @param yml_file user-specified file containing configuration details for the
#' pull.
#' @returns filepath for the .csv of the reformatted yaml file. Silently saves 
#' the .csv in the `data_acquisition/in` directory path.
#' 
#' 
format_yaml <-  function(yml_file) {
  yaml <-  read_yaml(yml_file)
  # create a nested tibble from the yaml file
  nested <-  map_dfr(names(yaml), 
                   function(x) {
                     tibble(set_name = x,
                            param = yaml[[x]])
                     })
  # create a new column to contain the nested parameter name and unnest the name
  nested$desc <- NA_character_
  unnested <- map_dfr(seq(1:length(nested$param)),
                     function(x) {
                       name <- names(nested$param[[x]])
                       nested$desc[x] <- name
                       nested <- nested %>% 
                         unnest(param) %>% 
                         mutate(param = as.character(param))
                       nested[x,]
                       })
  # re-orient to make it easy to grab necessary info in future functions
  unnested <- unnested %>% 
    select(desc, param) %>% 
    pivot_wider(names_from = desc, values_from = param)
  write_csv(unnested, 'data_acquisition/in/yml.csv')
  'data_acquisition/in/yml.csv'
}


#' Load in and format location file using config settings
#' 
#' @param yaml contents of the yaml .csv file
#' @returns filepath for the .csv of the reformatted location data or the message
#' 'Not configured to use site locations'. Silently saves 
#' the .csv in the `data_acquisition/in` directory path if configured for site
#' acquisition.
#' 
#' 
grab_locs <- function(yaml) {
  if (grepl('site', yaml$extent[1])) {
    locs <- read_csv(file.path(yaml$data_dir, yaml$location_file))
    # store yaml info as objects
    lat <- yaml$latitude
    lon <- yaml$longitude
    id <- yaml$unique_id
    # apply objects to tibble
    locs <- locs %>% 
      rename_with(~c('Latitude', 'Longitude', 'id'), any_of(c(lat, lon, id)))
    write_csv(locs, 'data_acquisition/in/locs.csv')
    return('data_acquisition/in/locs.csv')
  } else {
    message('Not configured to use site locations.')
  }
}



#' Function to use the optimal shapefile from get_WRS_detection() to define
#' the list of WRS2 tiles for branching
#' 
#' @param detection_method optimal shapefile from get_WRS_detection()
#' @param yaml contents of the yaml .csv file
#' @param locs 'locs' target
#' @returns list of WRS2 tiles
#' 
#' 
get_WRS_tiles <- function(detection_method, yaml, locs) {
  WRS <- read_sf('data_acquisition/in/WRS2_descending.shp')
  locations <- locs
  locs <- st_as_sf(locations, 
                   coords = c('Longitude', 'Latitude'), 
                   crs = yaml$location_crs[1])
  if (st_crs(locs) == st_crs(WRS)) {
    WRS_subset <- WRS[locs,]
  } else {
    locs = st_transform(locs, st_crs(WRS))
    WRS_subset <- WRS[locs,]
  }
  write_csv(st_drop_geometry(WRS_subset), 'data_acquisition/out/WRS_subset_list.csv')
  WRS_subset$PR
}
  

#' Function to run the Landsat Pull for a specified WRS2 tile.
#' 
#' @param WRS_tile tile to run the GEE pull on
#' @returns Silently writes a text file of the current tile (for use in the
#' Python script). Silently triggers GEE to start stack acquisition per tile.
#' 
#' 
run_GEE_per_tile <- function(WRS_tile) {
  write_lines(WRS_tile, 'data_acquisition/out/current_tile.txt', sep = '')
  source_python('data_acquisition/src/runGEEperTile.py')
}