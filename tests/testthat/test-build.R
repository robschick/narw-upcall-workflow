test_that("build writes the dictionary's table: every raw row, in log order", {
  cfg <- test_config()
  run_steps(cfg, "01_build")
  tbl <- nanoparquet::read_parquet(cfg$paths$table)

  expect_equal(nrow(tbl), 8256)
  expect_named(tbl, c("selection", "time", "time_end", "freq_low",
                      "freq_high", "confidence", "day"))
  expect_equal(attr(tbl$time, "tzone"), "UTC")
  # First raw row: 2009-03-28T00:03:08-05:00, Detected, day 1.
  expect_equal(tbl$time[1], as.POSIXct("2009-03-28 05:03:08", tz = "UTC"))
  expect_equal(as.character(tbl$confidence[1]), "Detected")
  expect_equal(sort(unique(tbl$day)), 1:7)
  expect_equal(sum(tbl$confidence == "Possibly_Detected"), 2351)
  # Log order is kept: time steps backwards 148 times.
  expect_equal(sum(diff(tbl$time) < 0), 148)
})

test_that("build stops when the table disagrees with the dictionary", {
  cfg <- test_config()
  bad_raw <- file.path(cfg$paths$output, "raw.csv")
  raw <- readLines(cfg$paths$raw)
  # A confidence level the dictionary doesn't allow.
  raw[2] <- sub('"Detected"$', '"Maybe"', raw[2])
  writeLines(raw, bad_raw)
  cfg$paths$raw <- bad_raw
  expect_error(run_steps(cfg, "01_build"), "data dictionary")
})
