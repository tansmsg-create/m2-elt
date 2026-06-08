SELECT
    customer_id AS id,
    --customer_unique_id,
    customer_zip_code_prefix,
    customer_city,
    customer_state
FROM {{ source('brazil_ecommerce', 'olist_customers_dataset') }}
WHERE customer_id IS NOT NULL
QUALIFY ROW_NUMBER() OVER (PARTITION BY id ORDER BY id DESC) = 1
