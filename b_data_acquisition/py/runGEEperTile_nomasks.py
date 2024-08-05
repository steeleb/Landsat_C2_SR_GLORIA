#import modules
import ee
import time
from datetime import date, datetime
import os 
import fiona
from pandas import read_csv

# get locations and yml from data folder
yml = read_csv('b_data_acquisition/in/yml.csv')

eeproj = yml['ee_proj'][0]
#initialize GEE
ee.Initialize(project = eeproj)

# get current tile
with open('b_data_acquisition/out/current_tile.txt', 'r') as file:
  tiles = file.read()

# get EE/Google settings from yml file
proj = yml['proj'][0]
proj_folder = yml['proj_folder'][0]

# get/save start date
yml_start = yml['start_date'][0]
yml_end = yml['end_date'][0]

# store run date for versioning
run_date = yml['run_date'][0]

if yml_end == 'today':
  yml_end = run_date

# gee processing settings
buffer = yml['site_buffer'][0]
cloud_filt = yml['cloud_filter'][0]
cloud_thresh = yml['cloud_thresh'][0]

try: 
  dswe = yml['DSWE_setting'][0].astype(str)
except AttributeError: 
  dswe = yml['DSWE_setting'][0]

# get extent info
extent = (yml['extent'][0]
  .split('+'))

if 'site' in extent:
  locations = read_csv('b_data_acquisition/in/locs.csv')
  # convert locations to an eeFeatureCollection
  locs_feature = csv_to_eeFeat(locations, yml['location_crs'][0])

if 'poly' in extent:
  #if polygon is in extent, check for shapefile
  shapefile = yml['polygon'][0]
  # if shapefile provided by user 
  if shapefile == True:
    # load the shapefile into a Fiona object
    with fiona.open('b_data_acquisition/out/user_polygon.shp') as src:
      shapes = ([ee.Geometry.Polygon(
        [[x[0], x[1]] for x in feature['geometry']['coordinates'][0]]
        ) for feature in src])
  else: #otherwise use the NHDPlus file
    # load the shapefile into a Fiona object
    with fiona.open('b_data_acquisition/out/NHDPlus_polygon.shp') as src:
      shapes = ([ee.Geometry.Polygon(
        [[x[0], x[1]] for x in feature['geometry']['coordinates'][0]]
        ) for feature in src])
  # Create an ee.Feature for each shape
  features = [ee.Feature(shape, {}) for shape in shapes]
  # Create an ee.FeatureCollection from the ee.Features
  poly_feat = ee.FeatureCollection(features)

if 'center' in extent:
  if yml['polygon'][0] == True:
    centers_csv = read_csv('b_data_acquisition/out/user_polygon_centers.csv')
    # load the shapefile into a Fiona object
    centers = csv_to_eeFeat(centers_csv, yml['poly_crs'][0])
  else: #otherwise use the NHDPlus file
    centers_csv = read_csv('b_data_acquisition/out/NHDPlus_polygon_centers.csv')
    centers = csv_to_eeFeat(centers_csv, 'EPSG:4326')
  # Create an ee.FeatureCollection from the ee.Features
  ee_centers = ee.FeatureCollection(centers)    
  

##############################################
##---- CREATING EE FEATURECOLLECTIONS   ----##
##############################################

wrs = (ee.FeatureCollection('projects/ee-ls-c2-srst/assets/WRS2_descending')
  .filterMetadata('PR', 'equals', tiles))

wrs_path = int(tiles[:3])
wrs_row = int(tiles[-3:])

#grab images and apply scaling factors
l7 = (ee.ImageCollection('LANDSAT/LE07/C02/T1_L2')
    .filter(ee.Filter.lt('CLOUD_COVER', ee.Number.parse(str(cloud_thresh))))
    .filterDate(yml_start, yml_end)
    .filterDate('1999-05-28', '2019-12-31') # for valid dates
    .filter(ee.Filter.eq('WRS_PATH', wrs_path))
    .filter(ee.Filter.eq('WRS_ROW', wrs_row)))
l5 = (ee.ImageCollection('LANDSAT/LT05/C02/T1_L2')
    .filter(ee.Filter.lt('CLOUD_COVER', ee.Number.parse(str(cloud_thresh))))
    .filterDate(yml_start, yml_end)
    .filter(ee.Filter.eq('WRS_PATH', wrs_path))
    .filter(ee.Filter.eq('WRS_ROW', wrs_row)))
# merge collections by image processing groups
ls57 = ee.ImageCollection(l5.merge(l7))

# existing band names
bn57 = (['SR_B1', 'SR_B2', 'SR_B3', 'SR_B4', 'SR_B5', 'SR_B7', 
  'QA_PIXEL', 'SR_CLOUD_QA', 'QA_RADSAT', 'ST_B6', 
  'ST_QA', 'ST_CDIST', 'ST_ATRAN', 'ST_DRAD', 'ST_EMIS',
  'ST_EMSD', 'ST_TRAD', 'ST_URAD'])

# new band names
bns57 = (['Blue', 'Green', 'Red', 'Nir', 'Swir1', 'Swir2', 
  'pixel_qa', 'cloud_qa', 'radsat_qa', 'SurfaceTemp', 
  'temp_qa', 'ST_CDIST', 'ST_ATRAN', 'ST_DRAD', 'ST_EMIS',
  'ST_EMSD', 'ST_TRAD', 'ST_URAD'])


#grab images and apply scaling factors
l8 = (ee.ImageCollection('LANDSAT/LC08/C02/T1_L2')
    .filter(ee.Filter.lt('CLOUD_COVER', ee.Number.parse(str(cloud_thresh))))
    .filterDate(yml_start, yml_end)
    .filter(ee.Filter.eq('WRS_PATH', wrs_path))
    .filter(ee.Filter.eq('WRS_ROW', wrs_row)))
l9 = (ee.ImageCollection('LANDSAT/LC09/C02/T1_L2')
    .filter(ee.Filter.lt('CLOUD_COVER', ee.Number.parse(str(cloud_thresh))))
    .filterDate(yml_start, yml_end)
    .filter(ee.Filter.eq('WRS_PATH', wrs_path))
    .filter(ee.Filter.eq('WRS_ROW', wrs_row)))


# merge collections by image processing groups
ls89 = ee.ImageCollection(l8.merge(l9))

# existing band names
bn89 = (['SR_B1', 'SR_B2', 'SR_B3', 'SR_B4', 'SR_B5', 'SR_B6', 'SR_B7', 
  'QA_PIXEL', 'SR_QA_AEROSOL', 'QA_RADSAT', 'ST_B10', 
  'ST_QA', 'ST_CDIST', 'ST_ATRAN', 'ST_DRAD', 'ST_EMIS',
  'ST_EMSD', 'ST_TRAD', 'ST_URAD'])

# new band names
bns89 = (['Aerosol','Blue', 'Green', 'Red', 'Nir', 'Swir1', 'Swir2',
  'pixel_qa', 'aerosol_qa', 'radsat_qa', 'SurfaceTemp', 
  'temp_qa', 'ST_CDIST', 'ST_ATRAN', 'ST_DRAD', 'ST_EMIS',
  'ST_EMSD', 'ST_TRAD', 'ST_URAD'])


##########################################
##---- LANDSAT 57 ACQUISITION      ----##
##########################################

## run the pull for LS57, looping through all extents from yml
for e in extent:
  
  geo = wrs.geometry()
  
  if e == 'site':
    ## get locs feature and buffer ##
    feat = (locs_feature
      .filterBounds(geo)
      .map(dp_buff))
    if e == 'poly':
      ## get the polygon stack ##
      feat = (poly_feat
        .filterBounds(geo))
      if e == 'center':
        ## get centers feature and buffer ##
        feat = (ee_centers
          .filterBounds(geo)
          .map(dp_buff))
      else: print('Extent not identified. Check configuration file.')
  
  ## process 57 stack
  #snip the ls data by the geometry of the location points    
  locs_stack_ls57 = (ls57
    .filterBounds(feat.geometry()) 
    # apply fill mask and scaling factors
    .map(apply_scale_factors))
  
  # rename bands for ease
  locs_stack_ls57 = locs_stack_ls57.select(bn57, bns57)
  
  # and pull DSWE1
  print('Starting Landsat 5, 7 DSWE1 acquisition for ' + e + ' configuration at tile ' + str(tiles))
  locs_out_57_D1 = locs_stack_ls57.map(ref_pull_57_DSWE1_nomask).flatten()
  locs_out_57_D1 = locs_out_57_D1.filter(ee.Filter.notNull(['med_Blue']))
  locs_srname_57_D1 = proj+'_point_LS57_C2_SRST_DSWE1_nomask_'+str(tiles)+'_v'+run_date
  locs_dataOut_57_D1 = (ee.batch.Export.table.toDrive(collection = locs_out_57_D1,
                                          description = locs_srname_57_D1,
                                          folder = "SR_GLORIA_no_mask",
                                          fileFormat = 'csv',
                                          selectors = ['system:index',
                                          'med_Blue', 'med_Green', 'med_Red', 'med_Nir', 'med_Swir1', 'med_Swir2', 
                                          'med_SurfaceTemp', 'med_temp_qa', 'med_atran', 'med_drad', 'med_emis',
                                          'med_emsd', 'med_trad', 'med_urad',
                                          'min_SurfaceTemp', 'min_cloud_dist',
                                          'sd_Blue', 'sd_Green', 'sd_Red', 'sd_Nir', 'sd_Swir1', 'sd_Swir2', 'sd_SurfaceTemp',
                                          'mean_Blue', 'mean_Green', 'mean_Red', 'mean_Nir', 'mean_Swir1', 'mean_Swir2', 
                                          'mean_SurfaceTemp',
                                          'kurt_SurfaceTemp', 
                                          'pCount_dswe_gt0', 'pCount_dswe1', 'pCount_dswe3', 'pCount_dswe1a',
                                          'prop_clouds','prop_hillShadow','mean_hillShade']))
  #Check how many existing tasks are running and take a break of 120 secs if it's >25 
  maximum_no_of_tasks(10, 120)
  #Send next task.                                        
  locs_dataOut_57_D1.start()



#########################################
##---- LANDSAT 89 SITE ACQUISITION ----##
#########################################

for e in extent:
  
  geo = wrs.geometry()
  
  # use extent configuration to define feature for pull
  if e == 'site':
    ## get locs feature and buffer ##
    feat = (locs_feature
      .filterBounds(geo)
      .map(dp_buff))
    if e == 'poly':
      ## get the polygon stack ##
      feat = (poly_feat
        .filterBounds(geo))
      if e == 'center':
        ## get centers feature and buffer ##
        feat = (ee_centers
          .filterBounds(geo)
          .map(dp_buff))
      else: print('Extent not identified. Check configuration file.')
  
  # snip the ls data by the geometry of the location points    
  locs_stack_ls89 = (ls89
    .filterBounds(feat.geometry()) 
    # apply fill mask and scaling factors
    .map(apply_scale_factors))
  
  # rename bands for ease
  locs_stack_ls89 = locs_stack_ls89.select(bn89, bns89)
  
  print('Starting Landsat 8, 9 DSWE1 acquisition for ' + e + ' configuration at tile ' + str(tiles))
  locs_out_89_D1 = locs_stack_ls89.map(ref_pull_89_DSWE1_nomask).flatten()
  locs_out_89_D1 = locs_out_89_D1.filter(ee.Filter.notNull(['med_Blue']))
  locs_srname_89_D1 = proj+'_point_LS89_C2_SRST_DSWE1_nomask_'+str(tiles)+'_v'+run_date
  locs_dataOut_89_D1 = (ee.batch.Export.table.toDrive(collection = locs_out_89_D1,
                                          description = locs_srname_89_D1,
                                          folder = "SR_GLORIA_no_mask",
                                          fileFormat = 'csv',
                                          selectors = ['system:index',
                                          'med_Aerosol', 'med_Blue', 'med_Green', 'med_Red', 'med_Nir', 'med_Swir1', 'med_Swir2', 
                                          'med_SurfaceTemp', 'med_temp_qa', 'med_atran', 'med_drad', 'med_emis',
                                          'med_emsd', 'med_trad', 'med_urad',
                                          'min_SurfaceTemp', 'min_cloud_dist',
                                          'sd_Aerosol', 'sd_Blue', 'sd_Green', 'sd_Red', 'sd_Nir', 'sd_Swir1', 'sd_Swir2', 'sd_SurfaceTemp',
                                          'mean_Aerosol', 'mean_Blue', 'mean_Green', 'mean_Red', 'mean_Nir', 'mean_Swir1', 'mean_Swir2', 
                                          'mean_SurfaceTemp',
                                          'kurt_SurfaceTemp', 
                                          'pCount_dswe_gt0', 'pCount_dswe1', 'pCount_dswe3', 'pCount_dswe1a',
                                          'prop_clouds','prop_hillShadow','mean_hillShade']))
  #Check how many existing tasks are running and take a break of 120 secs if it's >25 
  maximum_no_of_tasks(10, 120)
  #Send next task.                                        
  locs_dataOut_89_D1.start()



