# Render the report. It runs with the repo root as its working directory
# and reads only what the earlier steps saved.

quarto::quarto_render(cfg$paths$report, execute_dir = getwd(), quiet = TRUE)
message("Report written to ", sub("\\.qmd$", ".html", cfg$paths$report))
