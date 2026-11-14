# Tests run from tests/testthat; the repo root is two levels up.
root <- normalizePath(file.path("..", ".."))
source(file.path(root, "R", "functions.R"))

# Run numbered scripts with a given config, as run_all.R does.
run_steps <- function(cfg, steps) {
  env <- new.env()
  env$cfg <- cfg
  for (s in steps) source(file.path(root, "R", paste0(s, ".R")), local = env)
  invisible(env)
}

# The real config, writing the table, a copy of the dictionary, and all
# outputs to a fresh temp directory, so tests never touch data/ or output/.
test_config <- function() {
  cfg <- read_config(file.path(root, "config.yml"))
  tmp <- withr::local_tempdir(.local_envir = parent.frame())
  file.copy(cfg$paths$dict, tmp)
  cfg$paths$dict <- file.path(tmp, basename(cfg$paths$dict))
  cfg$paths$table <- file.path(tmp, basename(cfg$paths$table))
  cfg$paths$output <- tmp
  cfg
}
