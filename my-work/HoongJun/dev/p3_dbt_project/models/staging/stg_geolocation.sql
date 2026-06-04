-- Staging: geolocation. Cast lat/lng to float, drop Singer metadata.
-- No natural key (many coordinates per zip prefix), so dedupe only removes EXACT
-- duplicate rows from append re-runs. View, reads raw via source().

with source as (
    select * from {{ source('bronze', 'geolocation') }}
),

renamed as (
    select
        geolocation_zip_code_prefix,
        safe_cast(geolocation_lat as float64) as geolocation_lat,
        safe_cast(geolocation_lng as float64) as geolocation_lng,
        geolocation_city,
        geolocation_state
    from source
)

-- No key and BigQuery can't PARTITION BY float; DISTINCT drops exact dup rows from append re-runs.
select distinct * from renamed
