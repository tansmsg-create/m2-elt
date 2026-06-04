import csv as csvmod
import subprocess
from pathlib import Path

from dagster import multi_asset, AssetOut, AssetExecutionContext, Output, MetadataValue
from dagster_dbt import dbt_assets, DbtCliResource
from .resources import dbt_project

# The tap-csv -> target-bigquery (dataset: olin_bronze_dev_jun) project lives here
# (NOT p1_el itself — meltano needs the dir that contains meltano.yml as its cwd).
MELTANO_DIR = Path(__file__).parents[3] / "p1_el" / "meltano-raw-csv"
DATA_DIR = MELTANO_DIR / "data" / "raw"
BQ_PROJECT = "sctp-team2-project2-elt"
BQ_DATASET = "olin_bronze_dev_jun"
BQ_LOCATION = "US"

# stream/entity -> source CSV (must match the tap-csv `files` in meltano.yml).
# The BigQuery table name equals the entity name.
CSV_FILES = {
    "orders": "olist_orders_dataset.csv",
    "order_items": "olist_order_items_dataset.csv",
    "customers": "olist_customers_dataset.csv",
    "products": "olist_products_dataset.csv",
    "order_payments": "olist_order_payments_dataset.csv",
    "order_reviews": "olist_order_reviews_dataset.csv",
    "sellers": "olist_sellers_dataset.csv",
    "geolocation": "olist_geolocation_dataset.csv",
    "product_category_name_translation": "product_category_name_translation.csv",
}
BRONZE = list(CSV_FILES.keys())


def _csv_record_count(path: Path) -> int:
    """Accurate record count: excludes header, handles quoted multiline fields
    (order_reviews comments contain embedded newlines, so `wc -l` overcounts)."""
    with open(path, newline="", encoding="utf-8-sig") as f:
        return max(sum(1 for _ in csvmod.reader(f)) - 1, 0)


def _bq_row_counts(context) -> dict | None:
    """{table: COUNT(*)} from BigQuery bronze, or None if the BQ client is unavailable."""
    try:
        from google.cloud import bigquery
        from google.oauth2 import service_account
    except Exception as e:  # pragma: no cover - env without the lib
        context.log.warning(f"google-cloud-bigquery unavailable; skipping BQ verification ({e})")
        return None

    keyfile = None
    env = MELTANO_DIR / ".env"
    if env.exists():
        for line in env.read_text().splitlines():
            if line.strip().startswith("GOOGLE_APPLICATION_CREDENTIALS="):
                keyfile = line.split("=", 1)[1].strip()
    creds = (
        service_account.Credentials.from_service_account_file(keyfile)
        if keyfile and Path(keyfile).exists()
        else None
    )
    client = bigquery.Client(project=BQ_PROJECT, credentials=creds, location=BQ_LOCATION)

    counts = {}
    for t in BRONZE:
        try:
            q = f"SELECT COUNT(*) AS c FROM `{BQ_PROJECT}.{BQ_DATASET}.{t}`"
            counts[t] = list(client.query(q, location=BQ_LOCATION).result())[0].c
        except Exception:
            counts[t] = 0  # table missing => stream not loaded
    return counts


@multi_asset(
    outs={t: AssetOut(key=["raw_commerce", t]) for t in BRONZE},
    compute_kind="meltano",
)
def bronze_raw_commerce(context: AssetExecutionContext):
    """Load all Olist CSVs into BigQuery bronze via Meltano, then verify every
    CSV's record count landed in its bronze table. Per-table counts show up as
    asset metadata in the Dagster UI, and a summary is logged."""
    # 1) run the EL
    subprocess.run(
        ["meltano", "--environment=dev", "run", "tap-csv", "target-bigquery"],
        cwd=MELTANO_DIR, check=True,
    )

    # 2) verify CSV -> bronze row counts
    bq = _bq_row_counts(context)
    shortfalls = []
    context.log.info("=== Bronze load verification (CSV records vs BigQuery rows) ===")
    for t in BRONZE:
        csv_path = DATA_DIR / CSV_FILES[t]
        csv_rows = _csv_record_count(csv_path) if csv_path.exists() else None
        meta = {"csv_records": MetadataValue.int(csv_rows or 0)}

        if bq is not None:
            bq_rows = bq.get(t, 0)
            loaded = csv_rows is not None and bq_rows >= csv_rows
            exact = csv_rows is not None and bq_rows == csv_rows
            mark = "✅ exact" if exact else ("⚠️ appended (dupes)" if loaded else "❌ MISSING ROWS")
            meta.update({
                "bq_rows": MetadataValue.int(bq_rows),
                "status": MetadataValue.text(mark),
            })
            context.log.info(f"  {mark:22s} {t:34s} csv={csv_rows}  bq={bq_rows}")
            if not loaded:
                shortfalls.append(f"{t} (csv={csv_rows}, bq={bq_rows})")
        else:
            context.log.info(f"  {t:34s} csv={csv_rows}  (BQ check skipped)")

        yield Output(None, output_name=t, metadata=meta)

    if shortfalls:
        context.log.error(
            "Incomplete load — bronze has fewer rows than the source CSV for: "
            + ", ".join(shortfalls)
        )
    elif bq is not None:
        context.log.info("All bronze tables contain at least the full CSV record count. ✅")


@dbt_assets(manifest=dbt_project.manifest_path)
def dbt_models(context: AssetExecutionContext, dbt: DbtCliResource):
    yield from dbt.cli(["build"], context=context).stream()
