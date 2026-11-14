# Count calls in fixed-width bins on local clock time across the whole
# window. Empty bins are zero counts: effort was continuous.

message("03 bin")

width <- cfg$bin_width * 60  # seconds
starts <- seq(cfg$window$start, cfg$window$end - width, by = width)

calls <- readRDS(file.path(cfg$paths$output, "calls.rds"))
idx <- floor(as.numeric(calls$time - cfg$window$start, units = "secs") / width) + 1
idx <- idx[idx >= 1 & idx <= length(starts)]

mid <- starts + width / 2
bins <- tibble::tibble(
  bin  = starts,
  y    = tabulate(idx, nbins = length(starts)),
  day  = as.integer(as.Date(mid, tz = cfg$tz_local) -
                    as.Date(cfg$window$start, tz = cfg$tz_local)) + 1L,
  hour = lubridate::hour(mid) + lubridate::minute(mid) / 60,
  t    = as.numeric(mid - cfg$window$start, units = "hours")
) |>
  log_rows(paste0(cfg$bin_width, "-minute bins"))

saveRDS(bins, file.path(cfg$paths$output, "bins.rds"))
