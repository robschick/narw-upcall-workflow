# Turn the dictionary's table into the analysis set: filter by confidence,
# collapse same-start duplicates, sort by time. Every decision is in config.yml.

message("02 prepare")

calls <- nanoparquet::read_parquet(cfg$paths$table) |>
  log_rows("table") |>
  dplyr::filter(confidence %in% cfg$prepare$confidence_keep) |>
  log_rows(paste("confidence in", toString(cfg$prepare$confidence_keep)))

if (isTRUE(cfg$prepare$dedupe_same_start)) {
  # Keep the higher-confidence row of each pair (Detected sorts first).
  calls <- calls |>
    dplyr::arrange(time, factor(confidence, c("Detected", "Possibly_Detected"))) |>
    dplyr::distinct(time, .keep_all = TRUE) |>
    log_rows("one row per start time")
}

calls <- dplyr::arrange(calls, time)

saveRDS(calls, file.path(cfg$paths$output, "calls.rds"))
