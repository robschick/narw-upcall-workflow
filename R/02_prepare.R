# Turn the call table into a regular time series: the number of calls in
# each bin of local standard time, including bins with no calls.

narw_upcalls <- read_rds(cfg$paths$table)

calls <- narw_upcalls |>
  filter(confidence %in% cfg$confidence) |>
  mutate(time_local = with_tz(time, cfg$local_tz))

bin_width <- paste(cfg$bin_minutes, "mins")
effort <- ymd_hms(c(cfg$effort$start, cfg$effort$end), tz = cfg$local_tz)
bins <- seq(effort[1], effort[2] - minutes(cfg$bin_minutes), by = bin_width)

counts <- calls |>
  count(bin = floor_date(time_local, bin_width), name = "y") |>
  right_join(tibble(bin = bins), by = "bin") |>
  replace_na(list(y = 0L)) |>
  arrange(bin)

stopifnot(sum(counts$y) == nrow(calls), nrow(counts) == length(bins))

mid <- counts$bin + minutes(cfg$bin_minutes) / 2
binned <- counts |>
  mutate(
    day      = as.integer(as_date(bin) - as_date(effort[1])) + 1,
    hour     = hour(mid) + minute(mid) / 60,                        # time of day, 0-24
    t        = as.numeric(mid - effort[1], units = "hours"),         # hours since start
    lag_term = log1p(lag(y))                                         # previous bin
  ) |>
  # Drop the first bin (no previous bin) so every model uses the same rows.
  filter(!is.na(lag_term))

dir.create(cfg$paths$output, showWarnings = FALSE, recursive = TRUE)
write_rds(binned, file.path(cfg$paths$output, "binned.rds"))
