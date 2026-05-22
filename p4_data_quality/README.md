# Data Quality  (Module 4)
**Owner:** Charmaine · **Support:** Ang Jenn Fang · **Role:** Data Quality / Governance

## Purpose
Validate the pipeline at two levels: fast in-pipeline **dbt tests/contracts** on the gold models, and richer **Great Expectations** statistical/business-rule checks. Failing tests gate the gold marts.

## Needs (inputs)
- Gold (and silver) models built by M3.
- The star-schema contract from M2 (which columns/relationships must hold).

## Produces (outputs)
- dbt tests + enforced contracts (live in `p3_dbt_project/models/gold/_gold.yml`).
- Great Expectations suites (`great_expectations/`).
- Custom SQL validations (`sql_validations/`).
- A **QA report** summarizing pass/fail and any data issues.

## Hand-off to next (→ M5, M6)
- M5 can trust the gold marts because these gates passed.
- M6 runs these tests as part of the orchestrated pipeline; failures halt downstream.

## Coverage targets
- Every PK: unique + not_null.
- Every FK: relationship test to its dimension.
- Every enum: accepted_values (e.g. rfm_segment, review_score 1–5).
- ≥1 statistical check per gold mart (null-rate / range / distribution).

## Subfolders
- `great_expectations/` — GE suites + checkpoints.
- `sql_validations/` — custom SQL checks + the QA report.

## Run
```bash
cd p3_dbt_project && dbt test         # in-pipeline tests
python data_quality/run_ge.py      # Great Expectations suites
```
