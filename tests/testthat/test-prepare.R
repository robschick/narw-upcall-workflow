test_that("prepare keeps Detected calls, drops same-start duplicates, sorts by time", {
  cfg <- test_config()
  run_steps(cfg, c("01_build", "02_prepare"))
  calls <- readRDS(file.path(cfg$paths$output, "calls.rds"))

  # 5,905 Detected, of which four pairs share a start time.
  expect_equal(nrow(calls), 5901)
  expect_true(all(calls$confidence == "Detected"))
  expect_false(is.unsorted(calls$time))
  expect_false(anyDuplicated(calls$time) > 0)
})

test_that("confidence_keep in the config controls which calls are kept", {
  cfg <- test_config()
  cfg$prepare$confidence_keep <- c("Detected", "Possibly_Detected")
  run_steps(cfg, c("01_build", "02_prepare"))
  calls <- readRDS(file.path(cfg$paths$output, "calls.rds"))

  # 8,256 rows less the five duplicated start times.
  expect_equal(nrow(calls), 8251)
  # The mixed pair keeps its Detected row, so only one of the 2,351
  # Possibly_Detected rows goes.
  expect_equal(sum(calls$confidence == "Possibly_Detected"), 2350)
})
