# models / marts — dims, facts & marts  (MARTS layer)
**Module 3** · Owner: Hoong Jun / Bryan

## Purpose
The star schema and consumer marts that M5 and BI consume. Materialized as **BigQuery Iceberg** tables (open lakehouse).

## Needs
- Staging models (`../staging/`) as the only upstream — marts `ref()` staging, not raw.
- The BigLake catalog config (`catalogs.yml`) for Iceberg materialization.

## Produces
- `olin_gold_dev_jun.dim_customer / dim_product / dim_date / fct_order_items`
- `olin_gold_dev_jun.mart_customer_360` (RFM, lifetime value)
- `olin_gold_dev_jun.mart_monthly_revenue` (gmv by month × category)
- Iceberg/Parquet files in `gs://sctp-team2-project2-data/warehouse/`.

## Hand-off
- M4 attaches contracts + tests here via `_marts.yml`.
- M5 queries `olin_gold_dev_jun.mart_*` only.

## Files
- `_marts.yml` — model docs, **contracts**, and M4 tests.
- `dim_*.sql`, `fct_*.sql`, `mart_*.sql`.

## Config (every marts model)
Materialization is set at the folder level in `dbt_project.yml` (`+catalog_name: iceberg_marts`),
so individual models just need:
```sql
{{ config(materialized='table') }}
```
