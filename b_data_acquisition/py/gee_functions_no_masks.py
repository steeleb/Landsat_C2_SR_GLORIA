## Set up the reflectance pull
def ref_pull_57_DSWE1_nomask(image):
  """ This function applies all functions to the Landsat 4-7 ee.ImageCollection, extracting
  summary statistics for each geometry area where the DSWE value is 1 (high confidence water)

  Args:
      image: ee.Image of an ee.ImageCollection

  Returns:
      summaries for band data within any given geometry area where the DSWE value is 1
  """
  # process image with cfmask
  f = cf_mask(image).select('cfmask').selfMask().rename('clouds')
  h = calc_hill_shades(image, wrs.geometry()).select('hillShade')
  #calculate hillshadow
  hs = calc_hill_shadows(image, wrs.geometry()).select('hillShadow')
  #apply dswe function
  d = DSWE(image).select('dswe')
  gt0 = (d.gt(0).rename('dswe_gt0')
    .selfMask()
    )
  dswe1 = (d.eq(1).rename('dswe1')
    .selfMask()
    )
  # band where dswe is 3 and apply all masks
  dswe3 = (d.eq(3).rename('dswe3')
    .selfMask()
    )
  # define dswe 1a where d is not 0 and red/green threshold met
  grn_alg_thrsh = image.select('Green').gt(0.05)
  red_alg_thrsh = image.select('Red').lt(0.04)
  alg = (d.gt(1).rename('algae')
    .And(grn_alg_thrsh.eq(1))
    .And(red_alg_thrsh.eq(1))
    )
  dswe1a = (d.eq(1)
    .Or(alg.eq(1))
    .rename('dswe1a')
    .selfMask()
    )
  #calculate hillshade
  h = calc_hill_shades(image, wrs.geometry()).select('hillShade')
  #calculate hillshadow
  hs = calc_hill_shadows(image, wrs.geometry()).select('hillShadow')
  
  pixOut = (image.select(['Blue', 'Green', 'Red', 'Nir', 'Swir1', 'Swir2', 
                        'SurfaceTemp', 'temp_qa', 'ST_ATRAN', 'ST_DRAD', 'ST_EMIS',
                        'ST_EMSD', 'ST_TRAD', 'ST_URAD'],
                        ['med_Blue', 'med_Green', 'med_Red', 'med_Nir', 'med_Swir1', 'med_Swir2', 
                        'med_SurfaceTemp', 'med_temp_qa', 'med_atran', 'med_drad', 'med_emis',
                        'med_emsd', 'med_trad', 'med_urad'])
            .addBands(image.select(['SurfaceTemp', 'ST_CDIST'],
                                    ['min_SurfaceTemp', 'min_cloud_dist']))
            .addBands(image.select(['Blue', 'Green', 'Red', 
                                    'Nir', 'Swir1', 'Swir2', 'SurfaceTemp'],
                                  ['sd_Blue', 'sd_Green', 'sd_Red', 
                                  'sd_Nir', 'sd_Swir1', 'sd_Swir2', 'sd_SurfaceTemp']))
            .addBands(image.select(['Blue', 'Green', 'Red', 'Nir', 
                                    'Swir1', 'Swir2', 
                                    'SurfaceTemp'],
                                  ['mean_Blue', 'mean_Green', 'mean_Red', 'mean_Nir', 
                                  'mean_Swir1', 'mean_Swir2', 
                                  'mean_SurfaceTemp']))
            .addBands(image.select(['SurfaceTemp']))
            .updateMask(d.eq(1)) # only high confidence water
            .addBands(gt0) 
            .addBands(dswe1)
            .addBands(dswe3)
            .addBands(dswe1a)
            .addBands(f)
            .addBands(hs)
            .addBands(h)
            ) 
  combinedReducer = (ee.Reducer.median().unweighted()
      .forEachBand(pixOut.select(['med_Blue', 'med_Green', 'med_Red', 
            'med_Nir', 'med_Swir1', 'med_Swir2', 'med_SurfaceTemp', 
            'med_temp_qa','med_atran', 'med_drad', 'med_emis',
            'med_emsd', 'med_trad', 'med_urad']))
    .combine(ee.Reducer.min().unweighted()
      .forEachBand(pixOut.select(['min_SurfaceTemp', 'min_cloud_dist'])), sharedInputs = False)
    .combine(ee.Reducer.stdDev().unweighted()
      .forEachBand(pixOut.select(['sd_Blue', 'sd_Green', 'sd_Red', 'sd_Nir', 'sd_Swir1', 'sd_Swir2', 'sd_SurfaceTemp'])), sharedInputs = False)
    .combine(ee.Reducer.mean().unweighted()
      .forEachBand(pixOut.select(['mean_Blue', 'mean_Green', 'mean_Red', 
              'mean_Nir', 'mean_Swir1', 'mean_Swir2', 'mean_SurfaceTemp'])), sharedInputs = False)
    .combine(ee.Reducer.kurtosis().unweighted()
      .forEachBand(pixOut.select(['SurfaceTemp'])), outputPrefix = 'kurt_', sharedInputs = False)
    .combine(ee.Reducer.count().unweighted()
      .forEachBand(pixOut.select(['dswe_gt0', 'dswe1', 'dswe3', 'dswe1a'])), outputPrefix = 'pCount_', sharedInputs = False)
    .combine(ee.Reducer.mean().unweighted()
      .forEachBand(pixOut.select(['clouds', 'hillShadow'])), outputPrefix = 'prop_', sharedInputs = False)
    .combine(ee.Reducer.mean().unweighted()
      .forEachBand(pixOut.select(['hillShade'])), outputPrefix = 'mean_', sharedInputs = False)
    )
  # Collect median reflectance and occurance values
  # Make a cloud score, and get the water pixel count
  lsout = (pixOut.reduceRegions(feat, combinedReducer, 30))
  out = lsout.map(remove_geo)
  return out


def ref_pull_89_DSWE1_nomask(image):
  """ This function applies all functions to the Landsat 8 and 9 ee.ImageCollection, extracting
  summary statistics for each geometry area where the DSWE value is 1 (high confidence water)

  Args:
      image: ee.Image of an ee.ImageCollection

  Returns:
      summaries for band data within any given geometry area where the DSWE value is 1
  """
  f = cf_mask(image).select('cfmask').selfMask().rename('clouds')
  #calculate hillshade
  h = calc_hill_shades(image, wrs.geometry()).select('hillShade')
  #calculate hillshadow
  hs = calc_hill_shadows(image, wrs.geometry()).select('hillShadow')
  #apply dswe function
  d = DSWE(image).select('dswe')
  gt0 = (d.gt(0).rename('dswe_gt0')
    .selfMask()
    )
  dswe1 = (d.eq(1).rename('dswe1')
    .selfMask()
    )
  # band where dswe is 3 and apply all masks
  dswe3 = (d.eq(3).rename('dswe3')
    .selfMask()
    )
  # define dswe 1a where d is not 0 and red/green threshold met
  grn_alg_thrsh = image.select('Green').gt(0.05)
  red_alg_thrsh = image.select('Red').lt(0.04)
  alg = (d.gt(1).rename('algae')
    .And(grn_alg_thrsh.eq(1))
    .And(red_alg_thrsh.eq(1))
    )
  dswe1a = (d.eq(1)
    .Or(alg.eq(1))
    .rename('dswe1a')
    .selfMask()
    )
  pixOut = (image.select(['Aerosol', 'Blue', 'Green', 'Red', 'Nir', 'Swir1', 'Swir2', 
                      'SurfaceTemp', 'temp_qa', 'ST_ATRAN', 'ST_DRAD', 'ST_EMIS',
                      'ST_EMSD', 'ST_TRAD', 'ST_URAD'],
                      ['med_Aerosol', 'med_Blue', 'med_Green', 'med_Red', 'med_Nir', 'med_Swir1', 'med_Swir2', 
                      'med_SurfaceTemp', 'med_temp_qa', 'med_atran', 'med_drad', 'med_emis',
                      'med_emsd', 'med_trad', 'med_urad'])
          .addBands(image.select(['SurfaceTemp', 'ST_CDIST'],
                                  ['min_SurfaceTemp', 'min_cloud_dist']))
          .addBands(image.select(['Aerosol', 'Blue', 'Green', 'Red', 
                                  'Nir', 'Swir1', 'Swir2', 'SurfaceTemp'],
                                ['sd_Aerosol', 'sd_Blue', 'sd_Green', 'sd_Red', 
                                'sd_Nir', 'sd_Swir1', 'sd_Swir2', 'sd_SurfaceTemp']))
          .addBands(image.select(['Aerosol', 'Blue', 'Green', 'Red', 'Nir', 
                                  'Swir1', 'Swir2', 
                                  'SurfaceTemp'],
                                ['mean_Aerosol', 'mean_Blue', 'mean_Green', 'mean_Red', 'mean_Nir', 
                                'mean_Swir1', 'mean_Swir2', 
                                'mean_SurfaceTemp']))
          .addBands(image.select(['SurfaceTemp']))
          .updateMask(d.eq(1)) # only high confidence water
          .addBands(gt0) 
          .addBands(dswe1)
          .addBands(dswe3)
          .addBands(dswe1a)
          .addBands(f) 
          .addBands(hs)
          .addBands(h)
          ) 
  combinedReducer = (ee.Reducer.median().unweighted()
      .forEachBand(pixOut.select(['med_Aerosol', 'med_Blue', 'med_Green', 'med_Red', 
            'med_Nir', 'med_Swir1', 'med_Swir2', 'med_SurfaceTemp', 
            'med_temp_qa','med_atran', 'med_drad', 'med_emis',
            'med_emsd', 'med_trad', 'med_urad']))
    .combine(ee.Reducer.min().unweighted()
      .forEachBand(pixOut.select(['min_SurfaceTemp', 'min_cloud_dist'])), sharedInputs = False)
    .combine(ee.Reducer.stdDev().unweighted()
      .forEachBand(pixOut.select(['sd_Aerosol', 'sd_Blue', 'sd_Green', 'sd_Red', 'sd_Nir', 'sd_Swir1', 'sd_Swir2', 'sd_SurfaceTemp'])), sharedInputs = False)
    .combine(ee.Reducer.mean().unweighted()
      .forEachBand(pixOut.select(['mean_Aerosol', 'mean_Blue', 'mean_Green', 'mean_Red', 
              'mean_Nir', 'mean_Swir1', 'mean_Swir2', 'mean_SurfaceTemp'])), sharedInputs = False)
    .combine(ee.Reducer.kurtosis().unweighted()
      .forEachBand(pixOut.select(['SurfaceTemp'])), outputPrefix = 'kurt_', sharedInputs = False)
    .combine(ee.Reducer.count().unweighted()
      .forEachBand(pixOut.select(['dswe_gt0', 'dswe1', 'dswe3', 'dswe1a'])), outputPrefix = 'pCount_', sharedInputs = False)
    .combine(ee.Reducer.mean().unweighted()
      .forEachBand(pixOut.select(['clouds', 'hillShadow'])), outputPrefix = 'prop_', sharedInputs = False)
    .combine(ee.Reducer.mean().unweighted()
      .forEachBand(pixOut.select(['hillShade'])), outputPrefix = 'mean_', sharedInputs = False)
    )
  # Collect median reflectance and occurance values
  # Make a cloud score, and get the water pixel count
  lsout = (pixOut.reduceRegions(feat, combinedReducer, 30))
  out = lsout.map(remove_geo)
  return out

