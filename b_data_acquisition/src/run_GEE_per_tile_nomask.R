#' @title Run GEE script per tile
#' 
#' @description
#' Function to run the Landsat Pull for a specified WRS2 tile.
#' 
#' @param WRS_tile tile to run the GEE pull on
#' @returns Silently writes a text file of the current tile (for use in the
#' Python script). Silently triggers GEE to start stack acquisition per tile.
#' 
#' 
run_GEE_per_tile_nomask <- function(WRS_tile) {
  write_lines(WRS_tile, "b_data_acquisition/out/current_tile.txt", sep = "")
  source_python("b_data_acquisition/py/runGEEperTile_nomasks.py")
}