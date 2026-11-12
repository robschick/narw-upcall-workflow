# Run the whole workflow: raw log -> table -> hourly counts -> models ->
# comparison -> report. Run from the repo root:
#   Rscript run_all.R        or        source("run_all.R")

cfg <- yaml::read_yaml("config.yml")

scripts <- c(
  "R/00_packages.R",
  "R/functions.R",
  "R/01_build.R",
  "R/02_prepare.R",
  "R/03_fit.R",
  "R/04_compare.R",
  "R/05_report.R"
)

for (s in scripts) {
  message("== ", s)
  source(s, echo = FALSE)
}
