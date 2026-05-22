# Analytics  (Module 5)
**Owner:** John Phang · **Support:** Lim Chun Wei · **Role:** Analytics / BI

## Purpose
Turn the gold marts into insights: EDA, KPIs, visualizations, and business recommendations for the executive presentation.

## Needs (inputs)
- Gold marts (`gold_commerce.mart_customer_360`, `gold_commerce.mart_monthly_revenue`, `gold_commerce.fct_order_items`).
- These must have passed M4's quality gates.
- `pip install google-cloud-bigquery pandas plotly`.

## Produces (outputs)
- **`kpi_analysis.ipynb`** — EDA + KPI computations + charts.
- An insights/recommendations summary (feeds M7's report + deck).
- (Optional) a Looker Studio dashboard connected to `gold_commerce`.

## Hand-off to next (→ M7)
Charts + insights become the "findings" and "business value" sections of the final report and slide deck.

## KPIs to deliver
- Monthly GMV trend.
- Top product categories.
- Customer segments (RFM breakdown).
- Delivery lead-time by state; on-time rate.
- Repeat-purchase rate.

## Rule
Consume **gold marts only** — never query silver or raw. The marts are the contract.
