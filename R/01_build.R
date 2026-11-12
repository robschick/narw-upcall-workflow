# Build data/narw_upcalls.rds from the raw log, as described in
# data/data-dict.yaml. Light touch: nothing removed, re-sorted or
# de-duplicated. Stops if the result disagrees with the dictionary.

raw <- read_csv(cfg$paths$raw, show_col_types = FALSE)

# readr parses the ISO 8601 offsets (-05:00) to UTC instants.
narw_upcalls <- raw |>
  transmute(
    selection  = Selection,
    time       = Start_DateTime_ISO8601,
    time_end   = End_DateTime_ISO8601,
    freq_low   = Low.Freq..Hz.,
    freq_high  = High.Freq..Hz.,
    confidence = factor(Detection_Confidence, levels = c("Detected", "Possibly_Detected")),
    # One log file per local day; selection restarts at 1 in each file.
    day        = cumsum(selection == 1)
  )

# Checks against the dictionary ------------------------------------------

check <- function(ok, what) if (!isTRUE(ok)) stop("Build check failed: ", what, call. = FALSE)

check(nrow(narw_upcalls) == 8256, "8,256 rows")
check(identical(as.vector(table(narw_upcalls$confidence)), c(5905L, 2351L)),
      "5,905 Detected and 2,351 Possibly_Detected")
check(all(raw$Species == "RIWH"), "every row is a right whale")
check(!anyNA(narw_upcalls), "no missing values")
check(all(range(narw_upcalls$selection) == c(1, 2061)), "selection in [1, 2061]")
check(all(range(narw_upcalls$day) == c(1, 7)), "day in [1, 7]")
check(all(range(narw_upcalls$time) == ymd_hms(c("2009-03-28 05:03:08", "2009-04-04 03:26:25"))),
      "time range")
check(all(narw_upcalls$time_end >= narw_upcalls$time), "time_end >= time")
check(all(between(as.numeric(narw_upcalls$time_end - narw_upcalls$time, units = "secs"), 1, 4)),
      "calls last 1 to 4 seconds")
check(all(range(narw_upcalls$freq_low) == c(17.964, 256.2)), "freq_low range")
check(all(range(narw_upcalls$freq_high) == c(107.784, 584.022)), "freq_high range")
check(sum(diff(narw_upcalls$time) < 0) == 148, "time steps backwards 148 times")
check(sum(duplicated(narw_upcalls$time)) == 5, "five pairs share a start time")
# day must be the local (EST) date of each call, counted from 28 March.
local_day <- as.integer(as_date(with_tz(narw_upcalls$time, cfg$local_tz)) - as_date("2009-03-28")) + 1
check(all(local_day == narw_upcalls$day), "day matches the local date of every call")

dir.create(dirname(cfg$paths$table), showWarnings = FALSE, recursive = TRUE)
write_rds(narw_upcalls, cfg$paths$table)

# Per-day counts against Shiu et al. (2020, Sci Rep 10:607, Table 1).
# Informational only: their annotation set totals 9,683 calls.
day_counts <- narw_upcalls |>
  count(day, confidence) |>
  pivot_wider(names_from = confidence, values_from = n) |>
  mutate(all_rows = Detected + Possibly_Detected,
         shiu_2020 = c(767, 2280, 1663, 2206, 1328, 545, 894))
print(day_counts)
