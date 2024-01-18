# this script sets up a python virtual environment for use in this workflow

library('reticulate')

# increase timeout just in case
options(timeout=1000)

try(install_miniconda())

try(install_python(version = "3.8"))

py_install(envname = 'env/', c('earthengine-api', 'pandas', 'fiona', 'pyreadr'), 
           python_version = "3.8")

#create a conda environment named 'apienv' with the packages you need
conda_create(envname = file.path(getwd(), 'env'),
             python_version = "3.8",
             packages = c('earthengine-api', 'pandas', 'fiona', 'pyreadr'))

Sys.setenv(RETICULATE_PYTHON = file.path(getwd(), 'env/bin/python/'))

use_condaenv(file.path(getwd(), "env/"))
