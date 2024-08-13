
harmonize_column_names <- function(data, mission_id) {
  df_names <- names(data)[grepl("band", names(data))]
  if (mission_id %in% c("LANDSAT_4", "LANDSAT_5", "LANDSAT_7")) {
    remap <- list(
      Blue_insitu = "band_1",
      Green_insitu = "band_2",
      Red_insitu = "band_3",
      NIR_insitu = "band_4",
      SWIR1_insitu = "band_5"  # Adding SWIR1 for consistency, we'll drop it later
    )
  } else if (mission_id %in% c("LANDSAT_8", "LANDSAT_9")) {
    remap <- list(
      CA_insitu = "band_1",
      Blue_insitu = "band_2",
      Green_insitu = "band_3",
      Red_insitu = "band_4",
      NIR_insitu = "band_5"
    )
    } else {
      warning(paste0("No remap available for mission_id ", mission_id))
    }
    
  data %>%
    rename(!!!remap)
}