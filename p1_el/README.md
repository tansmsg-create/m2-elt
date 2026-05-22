# EL — Extract & Load  (Module 1)
**Owner:** John Phang · **Support:** Bryan Teo · **Role:** Data Engineering

## Purpose
Load the 9 raw Olist CSV files into BigQuery as the **bronze** layer (`raw_commerce`), 1:1 with source, with types inferred and load tracked.

## Needs (inputs)
- The 9 Olist CSVs in `p1_el/data/` (download from Kaggle: `olistbr/brazilian-ecommerce`).
- A configured GCP project + `raw_commerce` dataset (see Quick start below).
- GCP auth: `gcloud auth application-default login` **or** the service-account key.

## Produces (outputs)
- BigQuery dataset **`raw_commerce`** with 9 tables (orders, order_items, customers, products, payments, reviews, sellers, geolocation, category_translation).
- Load metadata (row counts, load ids) for audit.

## Hand-off to next (→ M3 dbt)
Publish the **raw table names + key columns** so M3 can write `silver_*` models against them. This is the M1→M3 contract; M3 can start once names are agreed, before loads finish.

## Two EL approaches (see subfolders)
- **`dlt/`** — V1 default. Pythonic, 9 CSVs in ~15 lines.
- **`meltano/`** — optional comparison. Config-driven EL via Singer taps.
Both land identical `raw_commerce.*` tables (EL-tool interchangeability behind one contract).

## Quick start
```bash
bq mk --location=ASIA-SOUTHEAST1 raw_commerce
python p1_el/dlt/load_olist.py
bq ls raw_commerce      # expect 9 tables
```
