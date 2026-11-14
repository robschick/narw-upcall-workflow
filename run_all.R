# Run the whole workflow, from the raw log to the report.
# Every decision lives in config.yml.

source("R/functions.R")
check_packages()
cfg <- read_config("config.yml")

source("R/01_build.R")
source("R/02_prepare.R")
source("R/03_bin.R")
source("R/04_fit.R")
