# Check that every package the workflow needs is installed. Stops with a
# single install.packages() line to copy if anything is missing.

pkgs <- c("yaml", "tidyverse", "mgcv", "RColorBrewer", "suncalc", "quarto", "knitr")

missing <- pkgs[!vapply(pkgs, requireNamespace, logical(1), quietly = TRUE)]
if (length(missing) > 0) {
  stop(
    "Missing packages. Install them with:\n  install.packages(c(",
    paste0('"', missing, '"', collapse = ", "), "))",
    call. = FALSE
  )
}

if (is.null(quarto::quarto_path())) {
  stop(
    "The Quarto command-line tool was not found. It comes with recent ",
    "RStudio and Positron, or install it from https://quarto.org/docs/get-started/",
    call. = FALSE
  )
}

suppressPackageStartupMessages({
  library(tidyverse)
  library(mgcv)
})
