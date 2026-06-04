# models / staging — cleaned & conformed  (STAGING layer)
**Module 3** · Owner: Hoong Jun / Bryan

## Purpose
Turn raw source data into clean, typed, conformed models. Staging folds in light intermediate prep (no separate intermediate folder, per project convention).

## Needs
- Raw sources registered in `_sources.yml` (points at `olin_bronze_dev_jun`).

## Produces
- `olin_silver_dev_jun.*` models (materialized as views): renamed columns, explicit casts, deduped, null-filtered, light joins/business prep.

## Hand-off
Marts models (`../marts/`) `ref()` these staging models — never the raw sources directly.

## Files
- `_sources.yml` — declares raw (`olin_bronze_dev_jun`) tables as dbt sources.
- `stg_<entity>.sql` — one per source entity (orders, order_items, customers, products, payments, reviews).

## Rules
- Cast types explicitly; no implicit casts.
- No engine-specific functions inline → use `macros/cross_db/`.
