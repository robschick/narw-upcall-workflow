# Helpers shared by the fit, compare and report steps.

# The model ladder. Each rung adds one idea to the one before.
model_spec <- function(name, cfg) {
  trend <- sprintf("s(t, k = %d)", cfg$k_trend)
  cycle <- sprintf("s(hour, bs = 'cc', k = %d)", cfg$k_hour)
  switch(name,
    M0 = list(rhs = "1",                                    family = "poisson"),
    M1 = list(rhs = trend,                                  family = "poisson"),
    M2 = list(rhs = paste(trend, "+", cycle),               family = "poisson"),
    M3 = list(rhs = paste(trend, "+", cycle),               family = "nb"),
    M4 = list(rhs = paste(trend, "+", cycle, "+ lag_term"), family = "nb"),
    stop("Unknown model: ", name, call. = FALSE)
  )
}

fit_model <- function(name, data, cfg) {
  spec <- model_spec(name, cfg)
  gam(
    as.formula(paste("y ~", spec$rhs)),
    family = if (spec$family == "poisson") poisson() else nb(),
    data   = data,
    knots  = list(hour = c(0, 24)),   # hour 24 wraps round to hour 0
    method = "REML"
  )
}

# Fitted mean and, for negative binomial fits, theta (Poisson: theta = Inf).
nb_theta <- function(fit) {
  if (grepl("^Negative Binomial", fit$family$family)) fit$family$getTheta(TRUE) else Inf
}

# Probability of each count y under mean mu, and the CDF; Poisson when theta = Inf.
dcount <- function(y, mu, theta, log = FALSE) {
  if (is.infinite(theta)) dpois(y, mu, log = log) else dnbinom(y, mu = mu, size = theta, log = log)
}
pcount <- function(y, mu, theta) {
  if (is.infinite(theta)) ppois(y, mu) else pnbinom(y, mu = mu, size = theta)
}

# Randomized quantile residuals (Dunn & Smyth 1996): standard normal if the
# model is right, whatever the count distribution.
rq_resid <- function(fit) {
  y <- fit$y
  mu <- fitted(fit)
  theta <- nb_theta(fit)
  u <- runif(length(y), pcount(y - 1, mu, theta), pcount(y, mu, theta))
  qnorm(u)
}

# Observed and expected number of bins per count class, for a hanging
# rootogram. Counts are grouped into classes `width` wide.
rootogram_data <- function(fit, width) {
  y <- fit$y
  mu <- fitted(fit)
  theta <- nb_theta(fit)
  top <- max(y) + width
  breaks <- seq(0, top + width, by = width)
  expected <- vapply(seq_len(length(breaks) - 1), function(i) {
    k <- breaks[i]:(breaks[i + 1] - 1)
    sum(vapply(k, function(kk) sum(dcount(kk, mu, theta)), numeric(1)))
  }, numeric(1))
  observed <- as.vector(table(cut(y, breaks, right = FALSE)))
  tibble(count = head(breaks, -1), observed, expected)
}

# Log-likelihood of new data under a fitted model.
loglik_new <- function(fit, newdata) {
  mu <- predict(fit, newdata, type = "response")
  sum(dcount(newdata$y, mu, nb_theta(fit), log = TRUE))
}

# Colours, all from RColorBrewer.
pal_models <- function(names) {
  setNames(RColorBrewer::brewer.pal(max(3, length(names)), "Dark2")[seq_along(names)], names)
}
