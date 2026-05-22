# Warehouse Design  (Module 2)
**Owner:** Charmaine · **Support:** Soon Meng · **Role:** Data Architecture / Modeling

## Purpose
Design the **star schema** that Module 3 (dbt) implements. This folder is the *design*, not the build — it defines the contract everyone downstream depends on.

## Needs (inputs)
- The bronze table shapes from M1 (`raw_commerce.*` columns).
- Understanding of the business questions M5 must answer (revenue, segmentation, delivery).

## Produces (outputs)
- **`erd.drawio`** — entity-relationship diagram of the dimensional model.
- **`star_schema.md`** — the dimensional model spec: dimensions, facts, grains, surrogate keys, and the consumer-mart column contracts.

## Hand-off to next (→ M3, M4, M5)
This is the **central contract**. Once `star_schema.md` is committed:
- M3 implements these exact dim/fct/mart shapes in dbt.
- M4 writes tests against these columns and relationships.
- M5 builds charts assuming these mart columns exist.
All three can work in parallel against this spec before M3 finishes building.

## Design summary (see star_schema.md for detail)
- **Dimensions:** dim_customer, dim_product, dim_seller, dim_date.
- **Fact:** fct_order_items (grain: one row per order line item).
- **Consumer marts:** mart_customer_360 (RFM, CLV), mart_monthly_revenue (gmv by month × category).
