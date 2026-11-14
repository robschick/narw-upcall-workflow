test_that("bins are 30-minute local-time counts covering the whole window", {
  cfg <- test_config()
  run_steps(cfg, c("01_build", "02_prepare", "03_bin"))
  bins <- readRDS(file.path(cfg$paths$output, "bins.rds"))

  expect_equal(nrow(bins), 336)
  expect_equal(bins$bin[1], as.POSIXct("2009-03-28 00:00:00", tz = "Etc/GMT+5"))
  expect_true(all(as.numeric(diff(bins$bin), units = "mins") == 30))
  expect_equal(sum(bins$y), 5901)
  expect_equal(bins$hour[1:2], c(0.25, 0.75))
  expect_equal(range(bins$day), c(1, 7))
  # Day 1, 00:00-00:30 EST: the first calls of the log.
  expect_gt(bins$y[1], 0)
})

test_that("bin_width in the config sets the bin count", {
  cfg <- test_config()
  cfg$bin_width <- 60
  run_steps(cfg, c("01_build", "02_prepare", "03_bin"))
  bins <- readRDS(file.path(cfg$paths$output, "bins.rds"))

  expect_equal(nrow(bins), 168)
  expect_equal(sum(bins$y), 5901)
})
