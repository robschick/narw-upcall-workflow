test_that("all four models are fitted to the same 336 bins", {
  cfg <- test_config()
  run_steps(cfg, c("01_build", "02_prepare", "03_bin", "04_fit"))
  fits <- readRDS(file.path(cfg$paths$output, "fits.rds"))

  expect_named(fits, c("pois", "nb", "lgcp", "lgcp_se"))
  expect_equal(unname(vapply(fits, nobs, numeric(1))), rep(336, 4))
  expect_equal(fits$pois$family$family, "poisson")
  expect_match(fits$nb$family$family, "Negative Binomial")
  expect_equal(fits$lgcp$family$family, "poisson")
  # The self-exciting model is the GAM LGCP plus one kernel smooth.
  expect_equal(length(fits$lgcp_se$smooth), length(fits$lgcp$smooth) + 1)
})
