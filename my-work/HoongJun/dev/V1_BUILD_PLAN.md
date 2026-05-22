# V1 Build Plan — GCP Lakehouse Showcase
## SCTP Team 2 · Project 2 · Reference Implementation: Olist E-Commerce

| Field | Value |
|---|---|
| Project | sctp-team2-project2 |
| Goal | A runnable, demoable open lakehouse on GCP, proving an end-to-end governed data pipeline |
| Dataset | Olist Brazilian E-Commerce (9 CSVs) |
| Platform | GCP managed (GCS + BigQuery Iceberg) — keeps infra ops near zero |
| Differentiator | Open lakehouse (Iceberg on our own GCS bucket), not just a BigQuery warehouse |
| Migration target | On-prem OSS (documented in MIGRATION.md, not built in V1) |
| Non-goals (future) | Multi-tenancy, HA, SLOs, on-call, ML serving, LLM/RAG, on-prem |

---

## 1. Team & Module Ownership

| Module | Lead | Support | Enterprise Role |
|---|---|---|---|
| 1. Data Ingestion | John Phang | Bryan Teo | Data Engineering |
| 2. Data Warehouse Design | Charmaine | Soon Meng | Data Architecture / Modeling |
| 3. ELT Pipeline (dbt) | **Hoong Jun** | Bryan Teo | Analytics Engineering |
| 4. Data Quality Testing | Charmaine | Ang Jenn Fang | Data Quality / Governance |
| 5. Data Analysis (Python) | John Phang | Lim Chun Wei | Analytics / BI |
| 6. Pipeline Orchestration | **Hoong Jun** | Soon Meng | Data Orchestration / Ops |
| 7. Docs & Exec Presentation | All | All | Cross-functional Delivery |

Hoong Jun leads Modules 3 (ELT/dbt) and 6 (Orchestration).

---

## 2. How the Modules Connect (the dependency chain)

The modules are not independent — they form a pipeline, and each owner consumes the previous owner's output. The shared contracts between them are what let everyone work in parallel.

```
M1 Ingestion (John)        →  raw_commerce.*           (raw tables in BigQuery)
M2 Warehouse Design        →  ERD + star schema spec   (the design dbt implements)
   (Charmaine)
M3 ELT / dbt (Hoong Jun)   →  stg_* + dim_/fct_/mart_  (Iceberg tables = the design, built)
M4 Data Quality            →  tests on M3's models     (gates the marts)
   (Charmaine)
M5 Analysis (John)         →  KPIs + charts from marts (consumes gold marts)
M6 Orchestration           →  runs M1→M3→M4 on schedule (wires it together)
   (Hoong Jun)
M7 Docs + Deck (All)       →  the story of all of it
```

**Two contracts unblock parallel work — agree these on day 1:**
1. **Raw table shapes (M1 → M3):** John publishes the raw table names + columns so Hoong Jun can write staging models against them before ingestion is finished.
2. **Mart schemas (M2/M3 → M4/M5):** Charmaine's star-schema design fixes the `dim_*`/`fct_*`/`mart_*` columns (§7). M4 and M5 build against that contract while M3 implements it.

This mirrors enterprise data-product contracts: producers and consumers agree on the interface, then build independently.

---

## 3. GCP Project Setup (Module 1 — John, day 1)

### 3.1 Prerequisites
- GCP account (free tier is plenty — Olist is ~50MB; free tier = 1TB queries + 10GB storage/month).
- `gcloud` CLI, Python 3.11+, `uv` or `poetry`.

### 3.2 Project + APIs
```bash
gcloud projects create sctp-team2-project2 --name="SCTP Team 2 Project 2"
gcloud config set project sctp-team2-project2
gcloud billing projects link sctp-team2-project2 --billing-account=YOUR_BILLING_ID

gcloud services enable \
  bigquery.googleapis.com \
  biglake.googleapis.com \
  storage.googleapis.com \
  bigqueryconnection.googleapis.com
```
> If `sctp-team2-project2` is taken (project IDs are globally unique), append a suffix, e.g. `sctp-team2-project2-1`, and keep the bucket name consistent.

### 3.3 GCS bucket (where Iceberg data physically lives)
```bash
gcloud storage buckets create gs://sctp-team2-project2-data \
  --location=ASIA-SOUTHEAST1 \
  --uniform-bucket-level-access
```

### 3.4 BigLake connection (lets BigQuery write Iceberg to the bucket)
```bash
bq mk --connection \
  --location=ASIA-SOUTHEAST1 \
  --connection_type=CLOUD_RESOURCE \
  sctp_team2_biglake_conn

bq show --connection ASIA-SOUTHEAST1.sctp_team2_biglake_conn
# grant the connection's service account access to the bucket:
gcloud storage buckets add-iam-policy-binding gs://sctp-team2-project2-data \
  --member="serviceAccount:THE_SA_FROM_ABOVE" \
  --role="roles/storage.objectAdmin"
```

### 3.5 BigQuery datasets (the medallion zones)
```bash
bq mk --location=ASIA-SOUTHEAST1 raw_commerce
bq mk --location=ASIA-SOUTHEAST1 stg_commerce
bq mk --location=ASIA-SOUTHEAST1 mart_commerce
```

### 3.6 Service account (shared by ingestion, dbt, orchestration)
```bash
gcloud iam service-accounts create sctp-team2-platform-sa
for ROLE in bigquery.admin bigquery.connectionAdmin storage.admin; do
  gcloud projects add-iam-policy-binding sctp-team2-project2 \
    --member="serviceAccount:sctp-team2-platform-sa@sctp-team2-project2.iam.gserviceaccount.com" \
    --role="roles/$ROLE"
done
gcloud iam service-accounts keys create ~/.gcp/sctp-team2-sa.json \
  --iam-account=sctp-team2-platform-sa@sctp-team2-project2.iam.gserviceaccount.com
```

**✅ Checkpoint:** `bq ls` shows three datasets; bucket exists; SA key downloaded. Share the SA key securely with Hoong Jun (M3) and Soon Meng (M6) — or better, each member uses their own user credentials via `gcloud auth application-default login` for the POC.

---

## 4. Repository Skeleton

```
sctp-team2-project2/
├── README.md
├── MIGRATION.md                  # GCP → on-prem OSS path (M7 deliverable)
├── pyproject.toml
├── .env.example                  # never commit real .env
├── ingestion/                    # MODULE 1 — John / Bryan
│   ├── load_olist.py             # ingestion scripts: CSV → BigQuery raw
│   └── sources.yml               # raw table manifest
├── warehouse_design/             # MODULE 2 — Charmaine / Soon Meng
│   ├── erd.drawio                # ERD diagram
│   └── star_schema.md            # dimensional model spec (the design)
├── dbt_project/                  # MODULE 3 — Hoong Jun / Bryan
│   ├── dbt_project.yml
│   ├── profiles.yml              # DUAL TARGET: bq (active) + trino (stub)
│   ├── catalogs.yml              # Iceberg / BigLake catalog config
│   ├── packages.yml
│   ├── models/
│   │   ├── staging/
│   │   │   ├── _sources.yml
│   │   │   └── stg_*.sql
│   │   └── marts/
│   │       ├── _marts.yml         # M4 contracts + tests attach here
│   │       ├── dim_customer.sql
│   │       ├── dim_product.sql
│   │       ├── dim_date.sql
│   │       ├── fct_order_items.sql
│   │       ├── mart_customer_360.sql
│   │       └── mart_monthly_revenue.sql
│   └── macros/
│       └── cross_db/              # MIGRATION SEAM — dialect quarantine
│           ├── day_diff.sql
│           └── surrogate_key.sql
├── data_quality/                 # MODULE 4 — Charmaine / Jenn Fang
│   ├── great_expectations/        # GE suites
│   └── sql_validations/           # custom SQL checks + QA report
├── analytics/                    # MODULE 5 — John / Chun Wei
│   └── kpi_analysis.ipynb
├── orchestration/                # MODULE 6 — Hoong Jun / Soon Meng
│   ├── definitions.py            # Dagster: dlt + dbt as assets (see §11)
│   └── .github/workflows/
│       └── trigger.yml           # thin cron to run the Dagster job headless
└── docs/                         # MODULE 7 — All
    ├── architecture.drawio
    ├── final_report.md
    └── presentation_outline.md
```

---

## 5. Migration Seams (Module 3 builds these in from commit 1)

These cost nothing now and turn the future on-prem migration into a config change. Keep them visible in the repo — they demonstrate platform-grade thinking and answer the brief's "why these tools / how does it scale" criteria.

### 5.1 Dual-target `profiles.yml`
```yaml
sctp_team2:
  target: bq                      # active now
  outputs:
    bq:                           # GCP managed lakehouse
      type: bigquery
      method: service-account
      keyfile: "{{ env_var('GCP_SA_KEYFILE') }}"
      project: "{{ env_var('GCP_PROJECT') }}"
      dataset: mart_commerce
      location: ASIA-SOUTHEAST1
      threads: 4
    trino:                        # FUTURE on-prem — stubbed, not used in V1
      type: trino
      host: "{{ env_var('TRINO_HOST', 'localhost') }}"
      port: 8080
      catalog: iceberg
      schema: mart_commerce
      threads: 4
```

### 5.2 Dialect quarantine via dispatch macros
Every engine-specific SQL function lives in ONE place. Migration rewrites ~5 macros, not 50 models.
```sql
-- macros/cross_db/day_diff.sql
{% macro day_diff(end_date, start_date) %}
  {{ return(adapter.dispatch('day_diff', 'sctp_team2')(end_date, start_date)) }}
{% endmacro %}

{% macro bigquery__day_diff(end_date, start_date) %}
  DATE_DIFF({{ end_date }}, {{ start_date }}, DAY)
{% endmacro %}

{% macro trino__day_diff(end_date, start_date) %}
  DATE_DIFF('day', {{ start_date }}, {{ end_date }})
{% endmacro %}
```
**Rule for the dbt team:** never write `DATE_DIFF`/`DATE_ADD`/`QUALIFY`/array functions directly in a model — route through a `cross_db` macro.

> **Gotcha:** the 2nd argument to `adapter.dispatch(...)` (`'sctp_team2'`) must equal the `name:` in `dbt_project.yml` (it's the macro namespace). And the `profiles.yml` top key (`sctp_team2:`) must equal the `profile:` field in `dbt_project.yml`. Keep all three aligned.

### 5.3 The other rules
1. **dbt owns every write** — no hand-written BQ DML outside dbt.
2. **Storage paths via vars**, never literals: `{{ var('storage_root') }}` not `gs://...`.
3. **dlt destination is a config block**, swappable bigquery → filesystem/iceberg.
4. **No BQ-proprietary features in committed models** (no BQ ML, no scripting).
5. **Pin Iceberg V2** in `catalogs.yml` so the table spec is identical on both ends.

### 5.4 Catalog choice — one conscious decision
- **V1 fast path:** BigLake Metastore (implicit) — simplest, ships the showcase fast, but no external Iceberg REST API (Trino can't read it later → migration needs a one-time, scriptable catalog re-registration; data files don't move).
- **Migration-friendly:** BigLake REST Catalog variant — standard Iceberg REST API (same protocol Nessie/Polaris speak).
- **Recommendation:** implicit metastore for V1; document the re-registration in MIGRATION.md; adopt REST catalog only when a second engine actually arrives.

---

## 6. Module 1 — Data Ingestion (John, support Bryan)

### Step 1.1 — Get Olist data
Download from Kaggle (`olistbr/brazilian-ecommerce`), unzip the 9 CSVs to `ingestion/data/`.

### Step 1.2 — Ingestion script: CSV → BigQuery `raw_commerce`
```python
# ingestion/load_olist.py — using dlt (handles schema inference + types + load tracking)
import dlt, pandas as pd, pathlib

FILES = {
    "orders": "olist_orders_dataset.csv",
    "order_items": "olist_order_items_dataset.csv",
    "customers": "olist_customers_dataset.csv",
    "products": "olist_products_dataset.csv",
    "payments": "olist_order_payments_dataset.csv",
    "reviews": "olist_order_reviews_dataset.csv",
    "sellers": "olist_sellers_dataset.csv",
    "geolocation": "olist_geolocation_dataset.csv",
    "category_translation": "product_category_name_translation.csv",
}

def olist_tables():
    base = pathlib.Path(__file__).parent / "data"
    for table, fname in FILES.items():
        df = pd.read_csv(base / fname)
        yield dlt.resource(df.to_dict("records"), name=table, write_disposition="replace")

pipeline = dlt.pipeline(
    pipeline_name="olist",
    destination="bigquery",          # MIGRATION SEAM: swap to filesystem/iceberg later
    dataset_name="raw_commerce",
)
print(pipeline.run(olist_tables()))
```
**Handle missing data / types:** dlt infers types; document any overrides (e.g., review timestamps with nulls, product category nulls) in `sources.yml` and the QA notes for M4.

**✅ Deliverable:** `bq ls raw_commerce` shows 9 tables; ingestion script + `sources.yml` committed.
**🤝 Hand-off to M3:** publish the raw table names + key columns so Hoong Jun can start staging models.

---

## 7. Module 2 — Warehouse Design (Charmaine, support Soon Meng)

Produces the design that Module 3 implements. The star schema (this is the contract for M3/M4/M5).

**Dimensions**
| Dim | Key | Notable attributes |
|---|---|---|
| dim_customer | customer_sk | customer_state, customer_city |
| dim_product | product_sk | category (EN), weight, dimensions |
| dim_seller | seller_sk | seller_state |
| dim_date | date_sk | year, month, weekday |

**Fact**
| Fact | Grain | Measures |
|---|---|---|
| fct_order_items | one row per order line item | price, freight_value, total_line_value, delivery_lead_time_days, review_score |

**Consumer marts (what M5 charts)**
- `mart_customer_360` — one row/customer: order_count, lifetime_value, recency_days, rfm_segment ∈ {champions, loyal, at_risk, hibernating, lost}
- `mart_monthly_revenue` — one row/(month × product_category): gmv, order_count

**✅ Deliverable:** ERD diagram + `star_schema.md`. This is the agreed contract — once committed, M3/M4/M5 build against it in parallel.

---

## 8. Module 3 — ELT / dbt (Hoong Jun, support Bryan)  ★ your lead

### Step 3.1 — `dbt_project.yml` essentials
```yaml
name: 'sctp_team2'        # must match dispatch namespace (§5.2)
profile: 'sctp_team2'     # must match profiles.yml top key
vars:
  storage_root: "gs://sctp-team2-project2-data/warehouse"
```

### Step 3.2 — `catalogs.yml` (BigQuery Iceberg)
```yaml
catalogs:
  - name: biglake_catalog
    active_write_integration: biglake_managed
    write_integrations:
      - name: biglake_managed
        catalog_type: biglake_metastore     # V1 fast path (§5.4)
        table_format: iceberg
        file_format: parquet
        storage_uri: "{{ var('storage_root') }}"
        connection: "projects/sctp-team2-project2/locations/asia-southeast1/connections/sctp_team2_biglake_conn"
```

### Step 3.3 — staging models (typed, renamed, cleaned)
```sql
-- models/staging/stg_orders.sql
select
  order_id,
  customer_id,
  order_status,
  cast(order_purchase_timestamp as timestamp) as purchased_at,
  cast(order_delivered_customer_date as timestamp) as delivered_at,
  cast(order_estimated_delivery_date as timestamp) as estimated_at
from {{ source('raw_commerce', 'orders') }}
where customer_id is not null
```

### Step 3.4 — marts as Iceberg tables (implements M2's design)
```sql
-- models/marts/fct_order_items.sql
{{ config(materialized='table', table_format='iceberg', catalog='biglake_catalog') }}

select
  {{ surrogate_key(['oi.order_id', 'oi.order_item_id']) }} as order_item_sk,
  {{ surrogate_key(['o.customer_id']) }}                   as customer_sk,
  {{ surrogate_key(['oi.product_id']) }}                   as product_sk,
  oi.price,
  oi.freight_value,
  oi.price + oi.freight_value                              as total_line_value,
  {{ day_diff('o.delivered_at', 'o.purchased_at') }}       as delivery_lead_time_days
from {{ ref('stg_order_items') }} oi
join {{ ref('stg_orders') }} o using (order_id)
```
Then `mart_customer_360` (RFM via quintile scoring) and `mart_monthly_revenue` (gmv by month × category).

### Step 3.5 — run it
```bash
cd dbt_project
dbt deps && dbt build
```
**✅ Deliverable:** staging + intermediate + marts models; `dbt build` green; marts queryable in BigQuery and Iceberg files visible in the GCS bucket under `warehouse/`.

---

## 9. Module 4 — Data Quality (Charmaine, support Jenn Fang)

Two layers: dbt tests (fast, in-pipeline) + Great Expectations (richer, statistical).

### Step 4.1 — dbt tests + contracts in `_marts.yml`
```yaml
models:
  - name: mart_customer_360
    config: { contract: { enforced: true } }
    columns:
      - name: customer_sk
        data_type: string
        constraints: [{ type: not_null }]
        tests: [unique, not_null]
      - name: rfm_segment
        data_type: string
        tests:
          - accepted_values: { values: [champions, loyal, at_risk, hibernating, lost] }
      - name: lifetime_value
        data_type: numeric
        tests:
          - dbt_utils.expression_is_true: { expression: ">= 0" }
  - name: fct_order_items
    columns:
      - name: customer_sk
        tests:
          - relationships: { to: ref('dim_customer'), field: customer_sk }
```

### Step 4.2 — Great Expectations suites
Validate the raw + mart layers: null-rate thresholds, value ranges (review_score 1–5), distribution checks (mean order value within bounds), referential integrity. Export a QA report.

**Coverage targets:** every PK unique+not_null; every FK relationship-tested; every enum accepted_values; ≥1 statistical check per mart.

**✅ Deliverable:** GE suites + SQL validations + QA report. Tests run as part of `dbt build` and in the orchestrated pipeline (M6).

---

## 10. Module 5 — Data Analysis (John, support Chun Wei)

```python
# analytics/kpi_analysis.ipynb
from google.cloud import bigquery
import plotly.express as px
client = bigquery.Client(project="sctp-team2-project2")

rev = client.query("SELECT * FROM mart_commerce.mart_monthly_revenue").to_dataframe()
px.line(rev.groupby('order_month').gmv.sum().reset_index(),
        x='order_month', y='gmv', title='Monthly GMV').show()

cust = client.query("SELECT * FROM mart_commerce.mart_customer_360").to_dataframe()
px.bar(cust.rfm_segment.value_counts().reset_index(),
       x='rfm_segment', y='count', title='Customers by RFM Segment').show()
```
**KPIs:** monthly GMV trend, top product categories, RFM segment breakdown, delivery lead-time by state, repeat-purchase rate.

**Optional zero-cost dashboard:** connect **Looker Studio** → BigQuery → `mart_commerce` for an interactive tile view to demo live.

**✅ Deliverable:** Jupyter notebook + charts + insights report. Consumes the gold marts only.

---

## 11. Module 6 — Orchestration (Hoong Jun, support Soon Meng)  ★ your lead

**Choice: Dagster** — asset-native orchestration that maps 1:1 onto dbt models and the dlt pipeline. Every raw table, staging model, and mart becomes a Dagster *asset*; the dependency graph IS the pipeline. This matches the platform vision and gives a far stronger demo than a cron log — you show the live asset lineage graph and click "Materialize all."

**Where Dagster runs (sub-decision):** Dagster has no free hosted scheduler the way GitHub Actions does, so:
- **Demo:** `dagster dev` locally — shows the asset graph live, materialize on click. This is the showcase centerpiece.
- **Unattended scheduling (pick one):**
  - **Hybrid (recommended for V1):** a thin GitHub Actions cron triggers a Dagster job → free, proves "runs unattended" without hosting Dagster.
  - **Cloud Run:** deploy the Dagster webserver + daemon as a container → real in-cloud scheduling, low cost, more setup. The production path.

### Step 6.1 — Dagster wraps dlt + dbt as assets
```python
# orchestration/definitions.py
from pathlib import Path
from dagster import Definitions, define_asset_job, ScheduleDefinition
from dagster_dbt import DbtCliResource, dbt_assets, DbtProject
from dagster_embedded_elt.dlt import DagsterDltResource, dlt_assets
from ingestion.load_olist import pipeline as olist_pipeline, olist_tables

DBT_PROJECT = DbtProject(project_dir=Path(__file__).parent.parent / "dbt_project")

# dlt ingestion as a Dagster asset (Module 1's pipeline)
@dlt_assets(dlt_source=olist_tables(), dlt_pipeline=olist_pipeline, name="olist_ingest")
def olist_dlt_assets(context, dlt: DagsterDltResource):
    yield from dlt.run(context=context)

# every dbt model (staging + marts) becomes an asset (Modules 3 + 4)
@dbt_assets(manifest=DBT_PROJECT.manifest_path)
def dbt_models(context, dbt: DbtCliResource):
    yield from dbt.cli(["build"], context=context).stream()   # build = run + test

# one job that runs the whole chain: ingest -> staging -> marts -> tests
full_pipeline = define_asset_job("full_pipeline", selection="*")

daily = ScheduleDefinition(job=full_pipeline, cron_schedule="0 18 * * *")  # 02:00 SGT

defs = Definitions(
    assets=[olist_dlt_assets, dbt_models],
    jobs=[full_pipeline],
    schedules=[daily],
    resources={
        "dlt": DagsterDltResource(),
        "dbt": DbtCliResource(project_dir=DBT_PROJECT),
    },
)
```

### Step 6.2 — run & demo
```bash
pip install dagster dagster-webserver dagster-dbt dagster-embedded-elt
cd orchestration && dagster dev          # open http://localhost:3000
# Asset graph shows: olist_ingest -> stg_* -> dim_*/fct_* -> mart_*  (+ tests)
# Click "Materialize all" to run the whole pipeline; watch lineage + run status live.
```

### Step 6.3 — unattended trigger (hybrid option)
```yaml
# orchestration/.github/workflows/trigger.yml — free cron that runs the Dagster job headless
name: nightly-pipeline
on:
  schedule: [{ cron: "0 18 * * *" }]
  workflow_dispatch: {}
jobs:
  run:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v5
        with: { python-version: "3.11" }
      - run: pip install -r requirements.txt
      - uses: google-github-actions/auth@v2
        with: { credentials_json: "${{ secrets.GCP_SA_KEY }}" }
      - name: Execute Dagster job headless
        run: dagster job execute -j full_pipeline -m orchestration.definitions
```

**✅ Deliverable:** Dagster project with the full asset graph; `dagster dev` runs the pipeline end-to-end (ingest → transform → test) with live lineage; scheduled via the hybrid GHA trigger (or Cloud Run).

> **Enterprise note for the deck:** Dagster's asset model is exactly how the production platform orchestrates — assets, partitions, sensors, retries, replay. On-prem this runs on Kubernetes (Helm) with its own Postgres for run storage. Same code, bigger runtime.

---

## 12. Module 7 — Docs & Presentation (All)

- **README** — setup, run instructions, architecture.
- **Architecture diagram** — the lakehouse flow (reuse from platform spec).
- **Final report** — technical approach + why each tool (the brief's evaluation criteria) + insights.
- **Slide deck** — exec summary → business value → architecture → insights → risks → roadmap (the V2+ ladder, §14).
- **MIGRATION.md** — the GCP → on-prem OSS sovereign path.

---

## 13. Definition of Done (the demo)

- [ ] Dagster `dagster dev` → asset graph shows ingest → marts → tests; "Materialize all" runs end-to-end live (M1+M3+M4+M6).
- [ ] BigQuery shows Iceberg marts; GCS bucket shows Parquet/Iceberg files (proves real lakehouse).
- [ ] Great Expectations QA report green (M4).
- [ ] Jupyter notebook + Looker Studio tell the segmentation story (M5).
- [ ] ERD + star schema documented (M2).
- [ ] README + final report + MIGRATION.md committed (M7).
- [ ] 10-min exec deck rehearsed by the team (M7).

---

## 14. Roadmap Slide — V2+ (where this goes)
1. **V2** — Elementary (data observability) + OpenLineage (column lineage).
2. **V3** — Feast feature view + one served model (delivery-delay prediction).
3. **V4** — BigLake REST catalog + Trino → proves engine interchangeability + a second domain.
4. **V5** — LiteLLM + Milvus + hybrid RAG assistant grounded on Olist reviews.
5. **V6** — CI/CD slim builds, contracts-in-CI, blue/green.
6. **Future** — on-prem OSS production (MIGRATION.md): k8s + MinIO + Nessie + Trino, HA, multi-tenant sovereign deployment.

---

## 15. Cost Guardrails
- Olist ~50MB; full rebuild scans <1GB; free tier = 1TB/month → effectively $0.
- Set a budget alert at $5 anyway.
- Looker Studio + GitHub Actions (public repo) are free.

---

## Appendix — MIGRATION.md skeleton (M7 deliverable)
```
# GCP → On-Prem OSS Migration Path
## Target: Kubernetes + MinIO + Nessie/Polaris + Trino + Dagster, self-hosted on-prem
## Carries over unchanged: all dbt models/tests/contracts, dlt sources, MetricFlow metrics,
##   the orchestration logic, and the Iceberg data files themselves
## Swaps: storage (GCS→MinIO), engine (BigQuery→Trino), catalog (BigLake→Nessie)
## Steps:
1. Stand up k8s + distributed MinIO + HA Postgres + Nessie + Trino (Helm).
2. Re-register Iceberg tables in Nessie (data files copy GCS→MinIO; metadata rebuilt).
3. Activate the `trino` target in profiles.yml; rewrite ~5 cross_db dispatch macros.
4. Repoint dlt destination bigquery → filesystem/iceberg.
5. `dbt build` against trino target; validate with the same M4 tests.
6. Add Vault (secrets), Keycloak (OIDC), SigNoz (observability), backup/DR.
## Effort: days for the data layer; the platform-ops layer (HA/DR/multi-tenant) is the larger, team-scale effort.
```
