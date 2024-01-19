# Landsat_C2_SR_GLORIA

Code to pull, collate, and correct Landsat SR product at GLORIA and other sites as presented in Maciel et al. 2023.

This repository is covered by the MIT use license. We request that all downstream uses of this work be available to the public when possible.

## Code Origin

The code presented in this repository is an adaptation of the code in the [ROSSyndicate repository Landsat_C2_SRST](https://github.com/rossyndicate/Landsat_C2_SRST). This code was written by members of the ROSSyndicate at Colorado State University and other contributors. The alterations from the original workflow are as follows:

1.  only targets that pull buffered location data are utilized (i.e. no center points or whole waterbodies are pulled)

2.  the buffer method has been altered from a circular buffer to a square buffer to match the methods in Maciel, et al 2023.

3.  all thermal data and related columns have been removed for the purposes of this analysis.

Not all location information to replicate the Maciel, et al. analysis using more stringent filters and correction coefficients. However, the locations of all GLORIA data are listed in the 'data' folder within the file "GLORIA_meta_and_lab.csv" and the filtered dataset from Maciel, et al is present in the "Matchups.csv".

## Data Origin

data/GLORIA_meta_and_lab.csv: <https://doi.pangaea.de/10.1594/PANGAEA.948492>

data/Matchups.csv: <https://doi.org/10.5281/zenodo.7829018>
