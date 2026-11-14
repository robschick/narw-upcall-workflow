# Run the whole workflow, from the raw log to the report.
# Every decision lives in config.yml.

source("R/functions.R")
check_packages()
cfg <- read_config("config.yml")

source("R/01_build.R")
source("R/02_prepare.R")
source("R/03_bin.R")
source("R/04_fit.R")
source("R/05_compare.R")

# The report only reads the saved outputs, so it can be re-rendered on its own.
if (is.null(quarto::quarto_path())) {
  message("\nAll model outputs are in ", cfg$paths$output, ", but the report ",
          "needs the Quarto CLI.\nInstall it from https://quarto.org/docs/get-started/ ",
          "and run source(\"run_all.R\") again.")
} else {
  message("06 report")
  # Rendered beside report.qmd, then moved: quarto's --output-dir would
  # empty the outputs directory first.
  quarto::quarto_render("report.qmd", quiet = TRUE)
  file.rename("report.html", file.path(cfg$paths$output, "report.html"))
  message("\nReport: ", file.path(cfg$paths$output, "report.html"))
}
