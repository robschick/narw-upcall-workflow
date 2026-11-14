# Fit the four models to the binned counts: Poisson GLM, negative binomial
# GLM, GAM LGCP, and GAM LGCP with a self-exciting kernel.

message("04 fit")

bins <- readRDS(file.path(cfg$paths$output, "bins.rds"))
fits <- fit_models(model_data(bins, cfg), cfg)

saveRDS(fits, file.path(cfg$paths$output, "fits.rds"))
