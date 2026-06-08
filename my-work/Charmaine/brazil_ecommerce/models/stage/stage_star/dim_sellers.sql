SELECT
    seller_id AS id,
    seller_zip_code_prefix,
    seller_city,
    seller_state,
    geolocation_lat,
    geolocation_lng,
    geolocation_city,
    geolocation_state
FROM {{ source('brazil_ecommerce', 'olist_sellers_dataset') }} sellers
LEFT JOIN {{ source('brazil_ecommerce', 'olist_geolocation_dataset') }} geolocation ON sellers.seller_zip_code_prefix = geolocation.geolocation_zip_code_prefix
WHERE seller_id IS NOT NULL
QUALIFY ROW_NUMBER() OVER (PARTITION BY id ORDER BY id DESC) = 1