# EL / dlt  — V1 default loader
**Module 1** · Owner: John / Bryan

## Purpose
Extract+Load the Olist CSVs into BigQuery `raw_commerce` using **dlt** (data load tool).

## Needs
- `p1_el/data/*.csv` (the 9 Olist files).
- GCP auth + `raw_commerce` dataset.
- `pip install dlt[bigquery] pandas`

## Produces
- `raw_commerce.*` tables (bronze), with dlt schema inference and load tracking.

## Files
- `load_olist.py` — the dlt pipeline (reads `../data/`, writes `raw_commerce`).
- `dlt_sources.yml` — source manifest; document any type/null overrides here.

## Migration seam
`destination="bigquery"` is a config swap → `filesystem`/`iceberg` for on-prem. Don't hardcode paths.

## Run
```bash
python load_olist.py
```
