{{ config(materialized='table') }}

-- The `dim_customer` model serves as a dimension table for customer-related data. 
-- It is built on top of the `stg_customers` staging model, which contains raw customer data ingested from the source. 
-- The `dim_customer` model selects relevant fields from the staging model and formats the `customer_key` as a string 
-- for consistency in the data warehouse. 
-- This model also includes metadata fields such as `created_at`, `updated_at`, `source_file`, `source_gcs_path`, 
-- and `batch_name` to facilitate data lineage and auditing.

SELECT
    customer_id AS customer_key,
    customer_id,
    customer_unique_id,
    customer_zip_code_prefix,
    customer_city,
    customer_state,

    created_at,
    updated_at,
    source_file,
    source_gcs_path,
    batch_name

FROM {{ ref('stg_customers') }}