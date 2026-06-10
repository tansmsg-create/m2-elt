SELECT
    order_id,
    order_item_id,
    product_id,
    seller_id,

    CAST(shipping_limit_date AS TIMESTAMP) AS shipping_limit_date,
    CAST(price AS NUMERIC) AS price,
    CAST(freight_value AS NUMERIC) AS freight_value,

    created_at,
    updated_at,
    is_deleted,
    source_file,
    source_gcs_path,
    batch_name

FROM {{ source('olist_bronze', 'oltp_olist_order_items') }}
WHERE COALESCE(is_deleted, FALSE) = FALSE