# SCTP Team 2 — Project 2
## Olist E-Commerce: End-to-End Data & ML Platform (V1, on GCP)

An open **lakehouse** pipeline: raw CSVs → BigQuery Iceberg → dbt star schema (medallion) → quality gates → analytics, orchestrated by Dagster. Built on GCP managed services for V1; designed to migrate to on-prem OSS (see `MIGRATION.md`).

> **Folder naming:** top-level folders are prefixed `p1_`…`p7_` to show pipeline order. Inner folders (dbt `models/`, `macros/`, `.github/workflows/`, etc.) stay bare because the tools require those exact names.

### Architecture at a glance (medallion)

| Tier | Where (BigQuery) | Produced by | Folder |
|---|---|---|---|
| **Bronze** | `raw_commerce` | dlt / Meltano (EL) | `p1_el/bronze/` (tier docs) |
| **Silver** | `silver_commerce` | dbt (cleaned, conformed) | `p3_dbt_project/models/silver/` |
| **Gold** | `gold_commerce` (Iceberg) | dbt (marts) | `p3_dbt_project/models/gold/` |

### Pipeline flow
```
p1_el (dlt/Meltano)   →  BRONZE raw_commerce
                              │
p3 dbt silver         →  SILVER silver_commerce  (clean/type/conform)
                              │
p3 dbt gold           →  GOLD gold_commerce      (dim_/fct_/mart_, Iceberg)
                              │
p4_data_quality       →  tests gate the gold marts
                              │
p5_analytics          →  KPIs, charts, insights
                              │
p6_orchestration      →  Dagster runs the whole chain on a schedule
```

### Folder map (every folder has its own README)
| Folder | Module | Owner | Produces |
|---|---|---|---|
| `p1_el/` | M1 Ingestion | John / Bryan | bronze raw tables (dlt + meltano) |
| `p1_el/bronze/` | M1 (tier) | John / Bryan | bronze tier contract/docs |
| `p2_warehouse_design/` | M2 Design | Charmaine / Soon Meng | ERD + star schema spec |
| `p3_dbt_project/` | M3 ELT | **Hoong Jun** / Bryan | silver + gold models |
| `p3_dbt_project/models/silver/` | M3 | Hoong Jun / Bryan | silver_commerce.* |
| `p3_dbt_project/models/gold/` | M3 | Hoong Jun / Bryan | gold_commerce.* (Iceberg) |
| `p3_dbt_project/macros/cross_db/` | M3 | Hoong Jun | migration-seam macros |
| `p3_dbt_project/tests/` | M3/M4 | Charmaine / Jenn Fang | singular/custom tests |
| `p3_dbt_project/seeds/` | M3 | Hoong Jun / Bryan | static reference tables |
| `p4_data_quality/` | M4 QA | Charmaine / Jenn Fang | tests + QA report |
| `p5_analytics/` | M5 Analysis | John / Chun Wei | notebooks + insights |
| `p6_orchestration/` | M6 Orchestration | **Hoong Jun** / Soon Meng | Dagster pipeline |
| `.github/workflows/` | M6 | Hoong Jun / Soon Meng | scheduled trigger + CI (must stay at root) |
| `p7_docs/` | M7 Docs | All | report + deck + diagrams |

### Quick start
```bash
# 1. GCP setup (see p1_el/README.md for full steps)
gcloud config set project sctp-team2-project2
# 2. Ingest (bronze)
python p1_el/dlt/load_olist.py
# 3. Transform + test (silver + gold)
cd p3_dbt_project && dbt deps && dbt build
# 4. Orchestrate (runs all of the above as assets)
cd p6_orchestration && dagster dev
```

### Project conventions
- **Medallion naming:** silver = staging + intermediate combined (no separate staging folder); bronze = the raw dataset EL lands.
- **Folder order:** `p1_`…`p7_` prefixes encode pipeline sequence; inner tool folders stay bare.
- **dbt owns all writes** to silver/gold — never hand-write SQL into those datasets.
- **Models read one tier down only:** silver←bronze, gold←silver. Never skip a tier.
- **Migration seams** (dual-target profiles, dialect macros) are intentional — see `MIGRATION.md`.