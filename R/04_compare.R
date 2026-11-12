# Compare the models three ways: AIC, residual checks, and leave-one-day-out
# cross-validation. Then pick one.

binned <- read_rds(file.path(cfg$paths$output, "binned.rds"))
fits <- read_rds(file.path(cfg$paths$output, "fits.rds"))

# 1. AIC ------------------------------------------------------------------

aic <- tibble(
  model = names(fits),
  edf   = map_dbl(fits, \(f) sum(f$edf)),
  AIC   = map_dbl(fits, AIC)
) |>
  mutate(dAIC = AIC - min(AIC), weight = exp(-dAIC / 2) / sum(exp(-dAIC / 2)))

# 2. Residual checks ------------------------------------------------------

set.seed(cfg$seed)
resid <- imap(fits, \(f, m) tibble(model = m, t = binned$t, resid = rq_resid(f))) |>
  list_rbind()

resid_acf <- resid |>
  group_by(model) |>
  reframe(lag = 1:24, acf = acf(resid, lag.max = 24, plot = FALSE)$acf[-1])

rootogram <- imap(fits, \(f, m) mutate(rootogram_data(f, width = 10), model = m)) |>
  list_rbind()

# 3. Leave-one-day-out cross-validation -----------------------------------
# Refit on six days, score the held-out day by its log-likelihood. M4 uses
# the observed count in the previous hour: hour-ahead prediction.

cv <- expand_grid(model = names(fits), day = sort(unique(binned$day))) |>
  mutate(loglik = map2_dbl(model, day, \(m, d) {
    fit <- fit_model(m, filter(binned, day != d), cfg)
    loglik_new(fit, filter(binned, day == d))
  }))

cv_total <- cv |>
  group_by(model) |>
  summarise(cv_loglik = sum(loglik)) |>
  mutate(d_cv = max(cv_loglik) - cv_loglik)

# Choice: best cross-validated log-likelihood; AIC breaks a tie.
comparison <- left_join(aic, cv_total, by = "model") |>
  arrange(desc(cv_loglik), AIC)
chosen <- comparison$model[1]
agree <- chosen == aic$model[which.min(aic$AIC)]

write_rds(
  list(comparison = comparison, cv = cv, resid = resid, resid_acf = resid_acf,
       rootogram = rootogram, chosen = chosen, agree = agree),
  file.path(cfg$paths$output, "comparison.rds")
)
message("Chosen model: ", chosen, if (agree) " (CV and AIC agree)" else " (CV and AIC disagree)")
