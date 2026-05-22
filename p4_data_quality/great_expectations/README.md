# data_quality / great_expectations
**Module 4** · Owner: Charmaine / Jenn Fang

## Purpose
Statistical and business-rule validation beyond what dbt's generic tests cover — distributions, value ranges, null-rate envelopes.

## Needs
- Built gold/silver tables in BigQuery.
- `pip install great_expectations`.

## Produces
- GE expectation suites + checkpoints + data docs (HTML report).

## Examples to implement
- review_score between 1 and 5.
- order_purchase timestamps within the dataset's valid window.
- lifetime_value >= 0; mean order value within historical bounds.
- referential integrity: every fct_order_items.customer_sk exists in dim_customer.
