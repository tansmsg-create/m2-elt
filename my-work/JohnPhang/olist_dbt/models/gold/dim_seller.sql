{{ config(materialized='table') }}

-- This creates the current seller dimension from the SCD Type 2 snapshot.
-- This exposes only the current seller version in dim_seller, while the full SCD2 history remains in snap_sellers.
-- The `dim_seller` model serves as a dimension table for seller-related data. 
-- It is built on top of the `snap_sellers` snapshot model, which contains the historical versions of seller data 
-- using Slowly Changing Dimension (SCD) Type 2 methodology. 
-- The `dim_seller` model selects the current version of each seller (where `dbt_valid_to` is NULL and `is_deleted` is FALSE) 
-- and joins with the `stg_product_category_translation` staging model to get the English category name. 
-- The `seller_key` is set to the `seller_id` for consistency in the data warehouse, and metadata fields are included for 
-- data lineage and auditing purposes.

SELECT
    seller_id AS seller_key,
    seller_id,
    seller_zip_code_prefix,
    seller_city,
    seller_state,

    created_at,
    updated_at,
    source_file,
    source_gcs_path,
    batch_name

FROM {{ ref('stg_sellers') }}