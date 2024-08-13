compile_rsr <- function(rsr_path, mission_id) {
  # get all the sheet names
  sheets <- excel_sheets(rsr_path)
  # drop the ones we don't care about
  rsr_sheets <- sheets[!grepl("plot|pan|summary|readme", sheets, ignore.case = T)]
  # read 'em all in, formatting is a bit different for 5/7, so deal with those separately
  if (mission_id %in% c("LANDSAT_5", "LANDSAT_7")) {
    rsrs <- map(rsr_sheets,
                function(sheet) {
                  df <- read_xlsx(rsr_path, 
                                  sheet = sheet) 
                  names(df) <- c("wavelength", sheet)
                  df
                }) 
    rsrs <- rsrs %>% reduce(., full_join)
    names(rsrs) <- c("wavelength", "band_1", "band_2", "band_3", "band_4",
                     "band_5", "band_7")
  } else if (mission_id == "LANDSAT_8") {
    rsrs <- map(rsr_sheets,
                function(sheet) {
                  df <- read_xlsx(rsr_path, 
                                  sheet = sheet) 
                  names(df) <- c("wavelength", sheet, "stdev")
                  df %>% 
                    select(-stdev)
                }) 
    rsrs <- rsrs %>% reduce(., full_join)
    names(rsrs) <- c("wavelength", "band_1", "band_2", "band_3", "band_4",
                     "band_5", "cirrus", "band_6", "band_7")
    rsrs <- rsrs %>% 
      select(-cirrus)
  } else if (mission_id == "LANDSAT_9") {
    rsrs <- map(rsr_sheets,
                function(sheet) {
                  df <- read_xlsx(rsr_path, 
                                  sheet = sheet) 
                  names(df) <- c("wavelength", sheet, "stdev")
                  df %>% 
                    select(-stdev)
                }) 
    rsrs <- rsrs %>% reduce(., full_join)
    names(rsrs) <- c("wavelength", "band_1", "band_2", "band_3", "band_4",
                     "band_5", "cirrus", "band_6", "band_7")
    rsrs <- rsrs %>% 
      select(-cirrus)
  } else { 
    print("Mission not recognized. Confirm mission_id is one of the following: LANDSAT_5, LANDSAT_7, LANDSAT_8, LANDSAT_9")
    stop()
  }
  # clean up the column names
  rsr_col_names <- names(rsrs) %>% 
    make_clean_names()
  names(rsrs) <- rsr_col_names
  # add mission id and return that df!
  rsrs %>% 
    mutate(mission = mission_id)
}
