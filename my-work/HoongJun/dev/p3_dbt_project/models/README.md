# models — dbt transformation layers
**Module 3** · Owner: Hoong Jun / Bryan

## Purpose
Holds the dbt models, organized by **dbt layer** (staging → marts). dbt owns the staging and marts layers (`olin_bronze_dev_jun` is the raw dataset produced upstream by EL).

## Structure
- **`staging/`** — cleaned, typed, conformed models. Materialized as views in `olin_silver_dev_jun`.
- **`marts/`** — dims, facts, consumer marts. Materialized as **Iceberg tables** in `olin_gold_dev_jun`.

## Flow
```
olin_bronze_dev_jun (raw)  →  models/staging/*  →  models/marts/*  →  consumers (M5/BI)
```

## Rule
Models only ever read from the layer directly below: staging reads raw sources; marts `ref()` staging. Never skip a layer.
