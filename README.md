# narw-upcall-workflow

A reproducible R workflow for one week of North Atlantic right whale up-call
detections: DCLDE 2013, Stellwagen Bank, 28 March to 3 April 2009. It starts
from the raw detection log, counts calls per hour, fits a ladder of five
count models, compares them, and writes a report.

The finished report is already in the repo: open `report/report.html` in a
browser.

## What it does

| Step | Script | Writes |
|---|---|---|
| Check packages | `R/00_packages.R` | – |
| Build the call table from the raw log and check it against `data/data-dict.yaml` | `R/01_build.R` | `data/narw_upcalls.rds` |
| Count calls per hour in local time | `R/02_prepare.R` | `output/series.rds`, `output/binned.rds` |
| Fit models M0–M4 | `R/03_fit.R` | `output/fits.rds` |
| Compare: AIC, residual checks, leave-one-day-out cross-validation | `R/04_compare.R` | `output/comparison.rds` |
| Render the report | `R/05_report.R` | `report/report.html` |

`R/functions.R` holds the helpers the steps share. `data/raw/` is the log as
published; nothing writes to it.

The models, each adding one idea to the one before:

- **M0** Poisson, constant rate
- **M1** + a smooth trend across the week
- **M2** + a daily cycle
- **M3** negative binomial instead of Poisson, for bursty counts
- **M4** + the previous hour's count, for bouts of calling

## Setting up

You need three things. None needs a compiler.

1. **R 4.1 or later** from <https://cran.r-project.org> (Windows or macOS).
2. **RStudio or Positron**. Both include Quarto, which renders the report.
   If you run R some other way, install Quarto from
   <https://quarto.org/docs/get-started/>.
3. **R packages**, installed once from the R console:

   ```r
   install.packages(c("yaml", "tidyverse", "mgcv", "RColorBrewer", "suncalc", "quarto", "knitr"))
   ```

   If any are missing when you run the workflow, it stops and prints this line
   for you.

## Running it

Clone or download the repo, then open the folder as the working directory:

- **RStudio:** File → Open Project (or set the working directory to the repo
  folder), then `source("run_all.R")`.
- **Positron:** File → Open Folder, then `source("run_all.R")`.
- **Terminal:** `Rscript run_all.R` from the repo folder.

It takes well under a minute. Everything in `data/narw_upcalls.rds`,
`output/` and `report/report.html` is rebuilt from the raw log each time.

On Windows, keep the repo in a path without unusual characters (e.g.
`C:/Users/you/narw-upcall-workflow`); OneDrive-synced folders sometimes lock
files while Quarto is writing.

## Changing the settings

All settings live in `config.yml`:

| Setting | What it does |
|---|---|
| `paths` | Where the raw log, the built table, the outputs and the report live. |
| `local_tz` | Time zone for the daily cycle. `Etc/GMT+5` is UTC−5, the fixed offset the log uses. |
| `recorder` | Recorder latitude and longitude, used for sunset and dusk times. |
| `effort` | Start and end of recording, local time. Hours inside this window with no calls count as zeros. |
| `confidence` | Which calls to keep: `[Detected]`, or `[Detected, Possibly_Detected]`. |
| `bin_minutes` | Width of each time bin. 60 gives hourly counts; try 30 or 15. |
| `k_trend`, `k_hour` | Flexibility of the weekly trend and the daily cycle. |
| `models` | Which rungs of the ladder to fit. |
| `seed` | Random seed for the randomized quantile residuals. |

The report's wording assumes the default settings (hourly bins, `Detected`
only, all five models); its numbers, tables and figures update with whatever
you choose.

## Data

The DCLDE 2013 workshop dataset, NOAA NCEI
(<https://www.ncei.noaa.gov/access/metadata/landing-page/bin/iso?id=gov.noaa.ncei.pad%3ADCLDE_2013>).
Public; fine to share and redistribute. See `data/data-dict.yaml` for every
column, and for the quirks of the log (out-of-order rows, duplicated start
times, the fixed −05:00 offset).
