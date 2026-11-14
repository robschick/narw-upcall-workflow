# narw-upcall-workflow

A reproducible R workflow for one week of North Atlantic right whale up-call
detections (DCLDE 2013, Stellwagen Bank, 28 March to 3 April 2009). It is the
take-home repo for a NARWC workshop: attendees will clone it, read it, and run
it at home on Windows or Mac.

- Read `data/data-dict.yaml` before writing any code. It describes the table
  the workshop built from the raw log. That build script isn't in this repo;
  building the table from `data/raw/` is part of the work.
- `data/raw/` is the log as published. Treat it as read-only.
- R, tidyverse where natural, succinct.
- CRAN packages only, pure R: it has to install anywhere without a compiler.
- A plain `run_all.R` runs the workflow, sourcing scripts in order.

## Agent skills

### Issue tracker

Issues and specs live in GitHub Issues for robschick/narw-upcall-workflow, via the `gh` CLI. See `docs/agents/issue-tracker.md`.

### Triage labels

Default vocabulary: needs-triage, needs-info, ready-for-agent, ready-for-human, wontfix. See `docs/agents/triage-labels.md`.

### Domain docs

Single-context: `GLOSSARY.md` and `docs/adr/` at the repo root. See `docs/agents/domain.md`.
