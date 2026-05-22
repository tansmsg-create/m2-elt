# Bronze — Raw Landing Tier  (medallion: BRONZE)
**Produced by:** Module 1 (EL — dlt / Meltano) · **Owner:** John / Bryan

## Purpose
Bronze is the **raw landing tier** of the medallion architecture: source data loaded 1:1, untransformed, as the immutable foundation everything else builds on. This folder documents the tier and holds bronze-level contracts/notes — the **data itself lives in BigQuery** (`raw_commerce`), produced by the EL tools in `../EL/`.

> Why a folder if the data is in BigQuery? For symmetry with `silver/`-via-dbt and `gold/`-via-dbt, and to give the bronze *contract* (table names, expected columns, load conventions) a documented home that M3 reads against.

## Needs (inputs)
- The 9 Olist CSVs landed by `../EL/dlt/` or `../p1_el/meltano/`.

## Produces (outputs / what bronze guarantees)
- BigQuery dataset **`raw_commerce`** with 9 tables, types inferred, load-tracked:
  `orders, order_items, customers, products, payments, reviews, sellers, geolocation, category_translation`.
- A stable **bronze contract**: table + key-column names that downstream silver models depend on.

## Hand-off to next (→ M3 silver)
dbt's `models/silver/_sources.yml` registers these `raw_commerce` tables as dbt **sources**. Silver models read from here via `{{ source('raw_commerce', '<table>') }}` — never from the CSVs directly.

## Contract notes (keep updated)
- Bronze is **append/replace only** — no business logic, no cleaning. Cleaning happens in silver.
- Document any known raw-data quirks here (e.g., `reviews` has null timestamps; `products` has null categories; `geolocation` has duplicate zip prefixes) so silver and M4 know what to handle.

## Files
- `bronze_contract.md` — (to author) the authoritative list of bronze tables + columns + known quirks.
