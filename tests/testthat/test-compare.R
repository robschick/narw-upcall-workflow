# One pipeline run shared by the tests below: the CV refits every model 7 times.
cfg <- test_config()
run_steps(cfg, c("01_build", "02_prepare", "03_bin", "04_fit", "05_compare"))
cmp <- readRDS(file.path(cfg$paths$output, "comparison.rds"))

test_that("compare scores every model on AIC and leave-one-day-out CV", {
  expect_setequal(cmp$metrics$model, c("pois", "nb", "lgcp", "lgcp_se"))
  expect_true(all(is.finite(cmp$metrics$aic)))
  # 4 models x 7 held-out days.
  expect_equal(nrow(cmp$cv), 28)
  expect_setequal(cmp$cv$day, 1:7)
  expect_true(all(is.finite(cmp$cv$loglik)))
  # Diagnostics for the report.
  expect_equal(nrow(cmp$resid), 4 * 336)
  expect_equal(nrow(cmp$kernel), cfg$models$max_lag)
  expect_setequal(cmp$smooth$model, c("lgcp", "lgcp_se"))
})

test_that("GAMs predict a held-out day from the field's prior, not by extrapolating", {
  # 48 bins per day; an unbounded smooth gave folds near -1e9.
  gams <- cmp$cv[cmp$cv$model %in% c("lgcp", "lgcp_se"), ]
  per_bin <- gams$loglik / 48
  expect_true(all(per_bin > -15), info = paste(round(per_bin), collapse = " "))
})
