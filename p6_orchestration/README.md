# Orchestration  (Module 6)
**Owner:** Hoong Jun · **Support:** Soon Meng · **Role:** Data Orchestration / Ops

## Purpose
Wire the whole pipeline together with **Dagster**: every dlt source and dbt model becomes an *asset*, so the dependency graph IS the pipeline. Run end-to-end on a schedule and on demand, with live lineage.

## Needs (inputs)
- The dlt pipeline (`p1_el/dlt/load_olist.py`).
- The dbt project (`p3_dbt_project/`).
- GCP auth available to the run environment.
- `pip install dagster dagster-webserver dagster-dbt dagster-embedded-elt`.

## Produces (outputs)
- **`definitions.py`** — Dagster assets (ingest → silver → gold → tests) + a `full_pipeline` job + daily schedule.
- A live asset-lineage view (the demo centerpiece).
- (Optional) `.github/workflows/trigger.yml` — a thin free cron that runs the Dagster job headless.

## Hand-off to next (→ M7)
The orchestrated run + asset graph is the "it all runs automatically end-to-end" story for the presentation.

## Run / demo
```bash
dagster dev        # http://localhost:3000 → "Materialize all"
# graph: olist_ingest -> silver_* -> dim_*/fct_*/mart_* (+ tests)
```

## Notes
- Dagster has no free hosted scheduler → demo with `dagster dev`; schedule via the GitHub Actions trigger (free) or Cloud Run (production).
- If Meltano is adopted for EL later, it runs as a Dagster asset (`meltano run` in an op) — same graph, no separate scheduler.
