-- 1:1 dedup of bronze olist_geolocation_raw to ONE row per zip prefix.
-- Bronze holds many lat/lng points per zip (and, since geolocation is loaded
-- append-only, multiple historical versions), so collapse to the LATEST version
-- per zip: order by source change time, then load time as a tiebreaker. Keeps the
-- seller/customer zip joins downstream from fanning out.
SELECT *
FROM {{ source('brazil_ecommerce', 'olist_geolocation_raw') }}
QUALIFY ROW_NUMBER() OVER (
    PARTITION BY geolocation_zip_code_prefix
    ORDER BY updated_at DESC, _sdc_batched_at DESC
) = 1
