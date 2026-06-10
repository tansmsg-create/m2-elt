{{ config(materialized='table') }}

-- This creates the current product dimension from the SCD Type 2 snapshot.
-- This exposes only the current product version in dim_product, while the full SCD2 history remains in snap_products.
-- The `dim_product` model serves as a dimension table for product-related data. 
-- It is built on top of the `snap_products` snapshot model, which contains the historical versions of product data 
-- using Slowly Changing Dimension (SCD) Type 2 methodology. 
-- The `dim_product` model selects the current version of each product (where `dbt_valid_to` is NULL and `is_deleted` is FALSE) 
-- and joins with the `stg_product_category_translation` staging model to get the English category name. 
-- The `product_key` is set to the `product_id` for consistency in the data warehouse, and metadata fields are included for 
-- data lineage and auditing purposes. 

WITH product_snapshot AS (

    SELECT
        product_id,
        product_category_name,
        product_name_lenght AS product_name_length,
        product_description_lenght AS product_description_length,
        product_photos_qty,
        product_weight_g,
        product_length_cm,
        product_height_cm,
        product_width_cm,

        created_at,
        updated_at,
        is_deleted,
        source_file,
        source_gcs_path,
        batch_name,

        dbt_valid_from,
        dbt_valid_to

    FROM {{ ref('snap_products') }}

    WHERE dbt_valid_to IS NULL
      AND COALESCE(is_deleted, FALSE) = FALSE

),

category_translation AS (

    SELECT
        product_category_name,
        product_category_name_english

    FROM {{ ref('stg_product_category_translation') }}

)

SELECT
    product_id AS product_key,
    p.product_id,

    p.product_category_name,
    COALESCE(t.product_category_name_english, p.product_category_name) AS product_category_name_english,

    p.product_name_length,
    p.product_description_length,
    p.product_photos_qty,
    p.product_weight_g,
    p.product_length_cm,
    p.product_height_cm,
    p.product_width_cm,

    p.dbt_valid_from AS valid_from,
    p.dbt_valid_to AS valid_to,
    TRUE AS is_current,

    p.created_at,
    p.updated_at,
    p.source_file,
    p.source_gcs_path,
    p.batch_name

FROM product_snapshot p

LEFT JOIN category_translation t
    ON p.product_category_name = t.product_category_name