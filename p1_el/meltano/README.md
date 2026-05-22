# EL / meltano  — optional comparison loader
**Module 1** · Owner: John / Bryan · **Status: optional (comparison only)**

## Purpose
Demonstrate the **alternative EL approach** using Meltano + Singer (`tap-csv` → `target-bigquery`), assuming Meltano handles full Extract+Load. Produces the same bronze tables as the dlt path, for a side-by-side "why we chose dlt" comparison.

## Needs
- `p1_el/data/*.csv` (shared with the dlt path, referenced as `../data/`).
- GCP auth + `raw_commerce` dataset.
- `pip install meltano` then `meltano install`.

## Produces
- Identical `raw_commerce.*` tables (proves EL interchangeability behind the same raw contract).

## Files
- `meltano.yml` — extractors (tap-csv) + loaders (target-bigquery).

## When to use
V1: optional, for the comparison slide. V4+: the path for real SaaS/DB sources with existing Singer taps — run **as a Dagster asset**, not Meltano's own scheduler.

## Run
```bash
meltano install
meltano run tap-csv target-bigquery
```
