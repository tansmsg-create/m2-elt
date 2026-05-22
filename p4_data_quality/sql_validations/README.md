# data_quality / sql_validations
**Module 4** · Owner: Charmaine / Jenn Fang

## Purpose
Custom SQL checks for business logic and reconciliation that are clearest as plain queries, plus the human-readable QA report.

## Needs
- Built gold tables.

## Produces
- SQL validation scripts (e.g., revenue reconciliation: sum in mart_monthly_revenue == sum in fct_order_items for the same period).
- `qa_report.md` — summary of checks, results, and any data caveats for the team and graders.
