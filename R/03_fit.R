# Fit each model in the ladder to the full week.

binned <- read_rds(file.path(cfg$paths$output, "binned.rds"))

fits <- set_names(cfg$models) |> map(fit_model, data = binned, cfg = cfg)

write_rds(fits, file.path(cfg$paths$output, "fits.rds"))
