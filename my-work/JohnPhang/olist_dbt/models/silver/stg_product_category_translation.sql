SELECT
    product_category_name,
    product_category_name_english,

    created_at,
    updated_at,
    is_deleted,
    source_file,
    source_gcs_path,
    batch_name

FROM {{ source('olist_bronze', 'oltp_product_category_name_translation') }}
WHERE COALESCE(is_deleted, FALSE) = FALSE