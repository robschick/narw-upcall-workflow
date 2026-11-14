# Helpers shared by the numbered scripts.

# Read config.yml, resolving `paths` relative to the config file.
read_config <- function(path = "config.yml") {
  cfg <- yaml::read_yaml(path)
  root <- dirname(normalizePath(path))
  cfg$paths <- lapply(cfg$paths, \(p) file.path(root, p))
  cfg$window <- lapply(cfg$window, lubridate::ymd_hms, tz = cfg$tz_local)
  cfg
}

# Stop with copy-paste install instructions if anything is missing.
check_packages <- function() {
  pkgs <- c("dplyr", "readr", "lubridate", "tidyr", "ggplot2", "RColorBrewer",
            "mgcv", "MASS", "yaml", "nanoparquet", "datadict", "quarto")
  missing <- pkgs[!vapply(pkgs, requireNamespace, logical(1), quietly = TRUE)]
  if (length(missing)) {
    stop("Missing packages. Run:\n  install.packages(c(",
         paste0('"', missing, '"', collapse = ", "), "))", call. = FALSE)
  }
  if (!nzchar(datadict::dd_path(check = FALSE))) {
    stop("The data-dict CLI is missing. Run once:\n  datadict::dd_install()",
         call. = FALSE)
  }
  invisible(TRUE)
}

# Print a step's row count so every removal is visible in the run log.
log_rows <- function(x, what) {
  message(sprintf("  %-40s %6d rows", what, nrow(x)))
  invisible(x)
}
