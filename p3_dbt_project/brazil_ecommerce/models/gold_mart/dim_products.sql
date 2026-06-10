-- Product dimension with English category. PK = dbt_scd_id (surrogate key).
-- References products_snapshot for SCD Type 2 history tracking.
-- One row per product version, not one row per product.
SELECT
    p.dbt_scd_id                            AS surrogate_key,
    p.product_id,
    t.product_category_name_english         AS product_category,
    p.product_name_lenght,
    p.product_description_lenght,
    p.product_photos_qty,
    p.product_weight_g,
    p.product_length_cm,
    p.product_height_cm,
    p.product_width_cm,
    p.dbt_valid_from                        AS valid_from,
    p.dbt_valid_to                          AS valid_to,
    CASE 
        WHEN p.dbt_valid_to IS NULL THEN TRUE 
        ELSE FALSE 
    END                                     AS is_current
FROM {{ ref('products_snapshot') }} p
LEFT JOIN {{ ref('stg_product_category_translation') }} t
    ON p.product_category_name = t.product_category_name