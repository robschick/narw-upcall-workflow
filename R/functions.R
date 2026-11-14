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

# Matrices for mgcv's distributed-lag term s(L, by = Y): row i, column j
# holds lag j and log1p of the count j bins earlier (0 before the series).
# `y` must be in time order.
lag_matrices <- function(y, max_lag) {
  n <- length(y)
  Y <- vapply(seq_len(max_lag), \(j) log1p(c(rep(0, min(j, n)), y)[seq_len(n)]),
              numeric(n))
  list(L = matrix(seq_len(max_lag), n, max_lag, byrow = TRUE),
       Y = matrix(Y, n, max_lag))
}

# Bins plus the lag matrices the self-exciting model needs. `bins` must be
# the full, time-ordered series so every row sees its real history.
model_data <- function(bins, cfg) {
  lags <- lag_matrices(bins$y, cfg$models$max_lag)
  bins$L <- lags$L
  bins$Y <- lags$Y
  bins
}

# Fit the four models to `d` (rows of model_data()). Reused by the CV.
fit_models <- function(d, cfg) {
  m <- cfg$models
  # Same parametric predictor for both GLMs: smooth trend plus a diel harmonic.
  glm_f <- y ~ splines::ns(t, df = m$glm_df) + sin(2 * pi * hour / 24) + cos(2 * pi * hour / 24)
  # GAM approximation to an LGCP: Poisson given a smooth latent field.
  lgcp_f <- y ~ s(t, bs = "gp", k = m$k_time) + s(hour, bs = "cc", k = m$k_hour)
  gam_fit <- \(f) mgcv::gam(f, family = poisson, data = d, method = "REML",
                            knots = list(hour = c(0, 24)))
  list(
    pois    = glm(glm_f, family = poisson, data = d),
    nb      = MASS::glm.nb(glm_f, data = d),
    lgcp    = gam_fit(lgcp_f),
    # Plus a log-linear self-exciting kernel over lags 1..max_lag.
    lgcp_se = gam_fit(update(lgcp_f, . ~ . + s(L, by = Y, k = m$k_lag)))
  )
}

# Print a step's row count so every removal is visible in the run log.
log_rows <- function(x, what) {
  message(sprintf("  %-40s %6d rows", what, nrow(x)))
  invisible(x)
}
