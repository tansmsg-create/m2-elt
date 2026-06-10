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
    batch_name
FROM {{ source('olist_bronze', 'oltp_olist_products') }}
WHERE COALESCE(is_deleted, FALSE) = FALSE