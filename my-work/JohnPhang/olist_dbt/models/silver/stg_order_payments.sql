SELECT
    order_id,
    payment_sequential,
    LOWER(TRIM(payment_type)) AS payment_type,
    payment_installments,
    CAST(payment_value AS NUMERIC) AS payment_value,

    created_at,
    updated_at,
    is_deleted,
    source_file,
    source_gcs_path,
    batch_name

FROM {{ source('olist_bronze', 'oltp_olist_order_payments') }}
WHERE COALESCE(is_deleted, FALSE) = FALSE