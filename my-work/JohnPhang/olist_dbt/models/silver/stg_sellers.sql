SELECT
    seller_id,
    seller_zip_code_prefix,
    LOWER(TRIM(seller_city)) AS seller_city,
    UPPER(TRIM(seller_state)) AS seller_state,

    created_at,
    updated_at,
    is_deleted,
    source_file,
    source_gcs_path,
    batch_name

FROM {{ source('olist_bronze', 'oltp_olist_sellers') }}
WHERE COALESCE(is_deleted, FALSE) = FALSE