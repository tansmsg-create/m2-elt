SELECT
    geolocation_zip_code_prefix,
    geolocation_city,
    geolocation_state,
    AVG(geolocation_lat) AS avg_geolocation_lat,
    AVG(geolocation_lng) AS avg_geolocation_lng,
    COUNT(*) AS source_row_count,
    MAX(updated_at) AS latest_updated_at

FROM {{ ref('stg_geolocation') }}

GROUP BY
    geolocation_zip_code_prefix,
    geolocation_city,
    geolocation_state