SELECT
    order_id,
    COUNT(*) AS payment_record_count,
    SUM(payment_value) AS total_payment_value,
    MAX(payment_installments) AS max_payment_installments,
    STRING_AGG(DISTINCT payment_type, ', ') AS payment_types,
    MAX(updated_at) AS latest_updated_at

FROM {{ ref('stg_order_payments') }}

GROUP BY order_id