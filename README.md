# Landsat_C2_SR_GLORIA

Code to pull, collate, and correct Landsat SR product at GLORIA and other sites as presented in Maciel et al. 2023 (<https://doi.org/10.1002/lol2.10344>).

This repository is covered by the MIT use license. We request that all downstream uses of this work be available to the public when possible.

## Code Architecture

This repository and analysis uses the {targets} package to create intelligent workflows. Because the GEE pull was run before adding additional {targets} groups, the functions are run in the file `b_data_acquisition.R`, but the 'src', 'in', and 'out' folders are in a folder that does not contain an indication of the targets group (i.e., 'data acquisition', without 'b' in this case). Changing the folder name from `data_acquisition` would invalidate that portion of the {targets} workflow, requiring a re-pull of the GEE data to become up to date.

The full pipeline is orchestrated using the \`run_targets.Rmd\` script. This also outlines the required software and packages/modules needed to run the pipeline.

## Code Origin

The code presented in this repository in targets group `b_data_acquisition` is an adaptation of the code in the [ROSSyndicate repository Landsat_C2_SRST](https://github.com/rossyndicate/Landsat_C2_SRST). This code was written by members of the ROSSyndicate at Colorado State University and other contributors. The alterations from the original workflow are as follows:

1.  only targets that pull buffered location data are utilized (i.e. no center points or whole waterbodies are pulled)

2.  the buffer method has been altered from a circular buffer to a square buffer to match the methods in Maciel, et al 2023

3.  remove Landsat 4 from the pull

Targets group `c_data_download_collation` is an adaptation of the code in the [ROSSyndicate repository NW-CLP-RS](https://github.com/rossyndicate/NW-CLP-RShttps://github.com/rossyndicate/NW-CLP-RS), specifically targets group `b_historical_RS_data_collation`.

Not all location information to replicate the Maciel, et al. analysis using different filters and correction coefficients were available. However, the locations of all GLORIA data are listed in the 'data' folder within the file "GLORIA_meta_and_lab.csv" and the filtered dataset from Maciel, et al is present in the "Matchups.csv". The missing location information are attributable to Pahlevan et al. 2022 (<https://doi.org/10.1016/j.rse.2021.112860>) and Maciel et al. 2021 (<https://doi.org/10.1016/j.isprsjprs.2021.10.009>). The filtered dataset likely represents a fraction of the sites from the upstream pre-filtered dataset, however, the GLORIA locations likely represent a large proportion of the data used in the Maciel et al 2023 study.

## Data Origin

data/GLORIA_meta_and_lab.csv: <https://doi.pangaea.de/10.1594/PANGAEA.948492>

data/Matchups.csv: <https://doi.org/10.5281/zenodo.7829018>
