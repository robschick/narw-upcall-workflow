# narw-upcall-workflow

One week of North Atlantic right whale up-call detections (DCLDE 2013,
Stellwagen Bank, 28 March to 3 April 2009), from the raw log to a comparison
of four count models of calling rate. This is the take-home repo for the
NARWC workshop.

## Run it

1. **Get the repo.** Clone it, or download the ZIP from GitHub and unzip it:

   ```sh
   git clone https://github.com/robschick/narw-upcall-workflow.git
   ```

2. **Install the R packages.** They are all on CRAN and need no compiler,
   on Windows or Mac:

   ```r
   install.packages(c("dplyr", "readr", "lubridate", "tidyr", "purrr", "tibble",
                      "ggplot2", "RColorBrewer", "mgcv", "MASS", "yaml",
                      "nanoparquet", "datadict", "quarto", "knitr", "rmarkdown"))
   ```

3. **Install the data-dictionary validator** (once per computer):

   ```r
   datadict::dd_install()
   ```

4. **Install the [Quarto CLI](https://quarto.org/docs/get-started/)** to get
   the report. Without it, the run still produces every model output, then
   tells you Quarto is missing.

5. **Run it.** Open R in the repo folder (or open the folder in RStudio or
   Positron) and run:

   ```r
   source("run_all.R")
   ```

   It takes about a minute. If a package is missing, it stops and prints one
   `install.packages(...)` line to copy.

**The report** is `output/report.html`. It is a single, self-contained file
that you can open offline or email.

## What's here

| Path | What it is |
|---|---|
| `config.yml` | Every data and model decision. Change these, not the code. |
| `run_all.R` | Runs the numbered scripts in order, then renders the report. |
| `R/01_build.R` | Builds the table in `data/data-dict.yaml` from the raw log and validates it. |
| `R/02_prepare.R` | Filters by confidence, collapses duplicate start times, sorts by time. |
| `R/03_bin.R` | Counts calls in 30-minute bins on local standard time (EST). |
| `R/04_fit.R` | Fits the four models. |
| `R/05_compare.R` | AIC, leave-one-day-out cross-validation, and diagnostics. |
| `R/functions.R` | Helpers shared by the scripts. |
| `report.qmd` | The report. It only reads saved outputs. |
| `data/raw/` | The detection log as published. Never edited. |
| `data/data-dict.yaml` | The data dictionary. Read it first. |

Each script reads its inputs from disk and writes to `output/`, so after one
full run you can re-run any single step by itself:

```r
source("R/functions.R"); cfg <- read_config()
source("R/05_compare.R")
```

## Tests

The tests are for developers. They need `testthat` and `withr`, and they
take about a minute:

```r
testthat::test_dir("tests/testthat")
```

## Data

The data are from the DCLDE 2013 workshop dataset, which NOAA NCEI
distributes as public data. See `data/data-dict.yaml` for the source, the
recorder, and the traps in the log.
