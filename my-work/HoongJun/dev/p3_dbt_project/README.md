# dbt Project — ELT / Transformation  (Module 3)
**Owner:** Hoong Jun · **Support:** Bryan Teo · **Role:** Analytics Engineering

## Purpose
Transform raw (`olin_bronze_dev_jun`) into the **staging** and **marts** dbt layers, implementing M2's star-schema design as governed, tested, versioned dbt models. Marts are materialized as **BigQuery Iceberg** tables (the lakehouse differentiator).

## Needs (inputs)
- Bronze tables in `olin_bronze_dev_jun` (from M1).
- The star-schema design from M2 (`p2_warehouse_design/star_schema.md`) — the spec these models implement.
- GCP auth + `olin_silver_dev_jun` and `olin_gold_dev_jun` datasets + the BigLake connection (for Iceberg).

## Produces (outputs)
- **`olin_silver_dev_jun.*`** — cleaned, typed, conformed models (`models/staging/`).
- **`olin_gold_dev_jun.*`** — dims, facts, consumer marts as Iceberg tables (`models/marts/`).
- dbt docs + lineage (`dbt docs generate`).

## Hand-off to next (→ M4, M5)
- M4 attaches tests/contracts to the marts models (`models/marts/_marts.yml`).
- M5 queries the marts (`olin_gold_dev_jun.mart_*`) for analysis.

## Layout
- `models/staging/` — staging = clean/type/conform (intermediate prep folded in).
- `models/marts/` — marts (dim_, fct_, mart_), materialized as Iceberg.
- `macros/cross_db/` — **migration seam**: dialect-specific SQL quarantined here.
- `profiles.yml` — dual target: `bq` (active) + `trino` (stubbed for on-prem).
- `catalogs.yml` — BigLake/Iceberg catalog config.

## Conventions
- **dbt owns every write** to staging/marts.
- Never write engine-specific SQL inline — route through a `cross_db` macro.
- `name:` and `profile:` in `dbt_project.yml` must both be `m2_elt` (matches dispatch namespace + profiles key).

## Setup
Scaffolded with dbt (BigQuery adapter) in the `elt` conda env (dbt-core 1.10.9 + dbt-bigquery 1.10.3).

1. **Activate the env:** `conda activate elt`
2. **Profile** (`profiles.yml`, git-ignored): profile `m2_elt`, target `bq`, project `sctp-team2-project2-elt`,
   location `US` (matches the raw dataset). Auth via service-account keyfile — set `GOOGLE_APPLICATION_CREDENTIALS`
   or rely on the fallback path in `profiles.yml`.
3. **Verify the connection:**
   ```bash
   dbt debug                 # expect "All checks passed!"
   ```
4. **Build the staging layer:**
   ```bash
   dbt build --select staging    # 8 views + tests into olin_silver_dev_jun
   ```
5. **Preview any source or model** (dbt is not a table browser — it only sees raw via `source()`):
   ```bash
   dbt show --inline "select * from {{ source('bronze','orders') }}" --limit 10
   dbt show --select stg_orders --limit 10
   ```

### Iceberg prerequisites (before building marts)
- GCS bucket `gs://sctp-team2-project2-data` must exist and be in the **`US`** location (same region as the datasets).
- The service account needs `roles/bigquery.connectionAdmin` + Storage Object Admin on that bucket,
  on top of the M1 `bigquery.dataEditor` / `bigquery.jobUser`.

## Run
```bash
dbt deps
dbt build      # runs + tests staging and marts
dbt docs generate && dbt docs serve
```

## Reset datasets (clean slate for Dagster orchestration)
> ⚠️ **Destructive.** This deletes the raw data in Bronze and every downstream view/table.
> Only run before a fresh end-to-end orchestration: Dagster re-runs the EL to repopulate Bronze,
> then dbt rebuilds Silver/Gold. Make sure datasets are recreated in **US** (matches everything else).
```bash
PROJ=sctp-team2-project2-elt

# drop the existing datasets (this time with the correct ID, so it actually works)
bq rm -r -f -d $PROJ:olin_bronze_dev_jun
bq rm -r -f -d $PROJ:olin_silver_dev_jun

# recreate empty Bronze in US (dbt remakes Silver itself)
bq mk --location=US $PROJ:olin_bronze_dev_jun
bq ls olin_bronze_dev_jun        # expect: empty / no tables
```

## Things to note (data quirks & gotchas)
**Raw data shape (from M1 EL):**
- Raw was loaded by **Meltano/Singer** (`target-bigquery`): every column lands as **STRING**, plus
  `_sdc_*` metadata columns. Staging casts real types (timestamp/int/numeric/float) and drops `_sdc_*`.
- The EL runs in **APPEND mode** → re-runs can duplicate rows. So **every staging model dedupes**:
  `QUALIFY row_number() over (partition by <key> order by _sdc_sequence desc) = 1`, or `SELECT DISTINCT`
  where there is no key. (0 dupes today; this is a forward guard, validated by the `unique` tests.)
- Dataset **location is `US`** (not `asia-southeast1`, despite the M1 app default) — `profiles.yml` uses
  `location: US`, and the Iceberg GCS bucket must also be `US`.

**dbt conventions used here:**
- Staging is **1:1 with source tables** — 8 raw tables → 8 `stg_*` models (thin: rename/cast/dedupe only;
  no joins/business logic — that belongs in marts).
- `macros/generate_schema_name.sql` makes `+dataset` names **verbatim** (e.g. `olin_silver_dev_jun`).
  Without it, dbt would prefix the target schema → `<target>_olin_silver_dev_jun`.
- Datasets are auto-created by dbt on first run (the SA can create datasets).

**BigQuery / dbt gotchas hit:**
- **Can't `PARTITION BY` a FLOAT64** column → `stg_geolocation` (lat/lng, no key) uses `SELECT DISTINCT`.
- **`dbt show` appends its own `LIMIT`** — don't put a `limit` inside the `--inline` query (use `--limit N`).
- The `models.m2_elt.marts` **"unused config path" warning** is benign until the first marts model exists.
- Source `products` has a **typo `lenght`** — fixed to `length` in `stg_products` (rename at staging).
- `profiles.yml` is **git-ignored** (points at a machine-local keyfile); teammates set their own keyfile
  or export `GOOGLE_APPLICATION_CREDENTIALS`.
