# Compare the four models: AIC, leave-one-day-out CV, and the diagnostics
# the report plots. No model is chosen automatically.

message("05 compare")

set.seed(cfg$seed)
bins <- readRDS(file.path(cfg$paths$output, "bins.rds"))
fits <- readRDS(file.path(cfg$paths$output, "fits.rds"))
d <- model_data(bins, cfg)

# Leave-one-day-out CV. The GAMs have no field estimate for the held-out day,
# so they integrate over the whole latent field (smooth + nugget); the
# self-exciting kernel still predicts one step ahead from observed history.
# Training drops the bins just after the held-out day whose lags reach into
# it, so no held-out count enters a fit.
cv <- purrr::map(unique(d$day), \(k) {
  test <- d$day == k
  after <- seq_along(test) > max(which(test)) &
           seq_along(test) <= max(which(test)) + cfg$models$max_lag
  train_fits <- fit_models(d[!test & !after, ], cfg)
  tibble::tibble(
    model  = names(train_fits),
    day    = k,
    loglik = purrr::map_dbl(train_fits, \(f) sum(pred_dist(f, d[test, ], c("s(t)", "s(id)"))$logd(d$y[test])))
  )
}) |>
  dplyr::bind_rows()

metrics <- tibble::tibble(
  model = names(fits),
  label = model_labels[names(fits)],
  df    = purrr::map_dbl(fits, \(f) attr(logLik(f), "df")),
  aic   = purrr::map_dbl(fits, AIC)
) |>
  dplyr::left_join(dplyr::summarise(cv, cv_loglik = sum(loglik), .by = model), by = "model") |>
  dplyr::mutate(d_aic = aic - min(aic), d_cv = max(cv_loglik) - cv_loglik)

resid <- purrr::imap(fits, \(f, m) tibble::tibble(
  model = m, bin = d$bin, t = d$t, resid = rq_resid(f, d)
)) |>
  dplyr::bind_rows()

resid_acf <- resid |>
  dplyr::reframe(
    lag = 1:48,
    acf = acf(resid, lag.max = 48, plot = FALSE)$acf[-1],
    .by = model
  )

# Hanging rootogram data: observed vs expected number of bins with each count.
# GAM expectations integrate over the nugget, as the residuals do.
rootogram <- purrr::imap(fits, \(f, m) {
  mu <- pred_dist(f, d)
  counts <- 0:max(d$y)
  tibble::tibble(
    model    = m,
    count    = counts,
    observed = tabulate(d$y + 1, nbins = length(counts)),
    expected = purrr::map_dbl(counts, \(k) sum(exp(mu$logd(k))))
  )
}) |>
  dplyr::bind_rows()

# Latent time smooths of the two GAMs, and the self-exciting kernel.
smooth_at <- \(f, newdata, term) {
  p <- predict(f, newdata = newdata, type = "terms", terms = term, se.fit = TRUE)
  list(fit = as.numeric(p$fit), se = as.numeric(p$se.fit))
}
smooth <- purrr::map(c("lgcp", "lgcp_se"), \(m) {
  s <- smooth_at(fits[[m]], d, "s(t)")
  tibble::tibble(model = m, t = d$t, bin = d$bin, fit = s$fit, se = s$se)
}) |>
  dplyr::bind_rows()

# Kernel at each lag: the effect of log1p(count) at that lag, i.e. Y = 1.
lags <- seq_len(cfg$models$max_lag)
kd <- d[seq_along(lags), ]
kd$L <- matrix(lags, ncol = 1)
kd$Y <- matrix(1, nrow = length(lags), ncol = 1)
k <- smooth_at(fits$lgcp_se, kd, "s(L):Y")
kernel <- tibble::tibble(
  lag = lags, hours = lags * cfg$bin_width / 60, fit = k$fit, se = k$se
)

kcheck <- purrr::map(c("lgcp", "lgcp_se"), \(m) {
  kc <- mgcv::k.check(fits[[m]])
  tibble::tibble(model = m, term = rownames(kc), tibble::as_tibble(unclass(kc)))
}) |>
  dplyr::bind_rows() |>
  dplyr::filter(term != "s(id)")  # k-index is meaningless for a random effect

saveRDS(
  list(metrics = metrics, cv = cv, resid = resid, resid_acf = resid_acf,
       rootogram = rootogram, smooth = smooth, kernel = kernel, kcheck = kcheck),
  file.path(cfg$paths$output, "comparison.rds")
)
