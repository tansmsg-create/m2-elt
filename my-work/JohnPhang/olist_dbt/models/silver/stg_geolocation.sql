SELECT
    geolocation_zip_code_prefix,
    CAST(geolocation_lat AS FLOAT64) AS geolocation_lat,
    CAST(geolocation_lng AS FLOAT64) AS geolocation_lng,
    LOWER(TRIM(geolocation_city)) AS geolocation_city,
    UPPER(TRIM(geolocation_state)) AS geolocation_state,

    created_at,
    updated_at,
    is_deleted,
    source_file,
    source_gcs_path,
    batch_name

FROM {{ source('olist_bronze', 'oltp_olist_geolocation') }}
WHERE COALESCE(is_deleted, FALSE) = FALSE