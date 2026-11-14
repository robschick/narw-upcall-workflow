test_that("lag matrices hold lag indices and log1p earlier counts, zero before the series", {
  lags <- lag_matrices(c(3, 0, 7, 1), max_lag = 2)

  expect_equal(lags$L, matrix(c(1, 1, 1, 1, 2, 2, 2, 2), nrow = 4))
  expect_equal(lags$Y, matrix(log1p(c(0, 3, 0, 7,     # lag 1
                                      0, 0, 3, 0)),   # lag 2
                              nrow = 4))
})

test_that("a lag longer than the series is all zeros", {
  lags <- lag_matrices(c(5, 5), max_lag = 3)
  expect_equal(dim(lags$Y), c(2, 3))
  expect_equal(lags$Y[, 3], c(0, 0))
})
