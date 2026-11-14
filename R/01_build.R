# Build the table described in data/data-dict.yaml from the raw log, and
# validate it against the dictionary. Light-touch by design: nothing is
# removed, re-sorted or de-duplicated here (see 02_prepare.R).

message("01 build")

raw <- readr::read_csv(cfg$paths$raw, show_col_types = FALSE)

upcalls <- raw |>
  dplyr::transmute(
    selection  = Selection,
    # The log's fixed -05:00 offset is parsed to the UTC instant.
    time       = lubridate::ymd_hms(Start_DateTime_ISO8601, tz = "UTC"),
    time_end   = lubridate::ymd_hms(End_DateTime_ISO8601, tz = "UTC"),
    freq_low   = Low.Freq..Hz.,
    freq_high  = High.Freq..Hz.,
    confidence = Detection_Confidence,
    # Deployment day by local date, 1 = 28 March 2009.
    day = as.integer(as.Date(lubridate::with_tz(time, cfg$tz_local), tz = cfg$tz_local) -
                     as.Date(cfg$window$start, tz = cfg$tz_local)) + 1L
  ) |>
  log_rows("raw log")

nanoparquet::write_parquet(upcalls, cfg$paths$table)

# validate-data exits non-zero if the data disagree with the dictionary.
report <- file.path(cfg$paths$output, "data-dict-report.html")
dir.create(cfg$paths$output, showWarnings = FALSE)
tryCatch(
  datadict::dd_run(c("validate-data", cfg$paths$dict, "--html", report)),
  error = \(e) stop("The table disagrees with its data dictionary. See ",
                    report, "\n", conditionMessage(e), call. = FALSE)
)
