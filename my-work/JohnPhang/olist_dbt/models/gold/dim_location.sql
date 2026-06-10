{{ config(materialized='table') }}

-- This uses the deduplicated geolocation model.
-- The `dim_location` model serves as a dimension table for location-related data. 
-- It is built on top of the `int_geolocation_by_zip` intermediate model, which contains aggregated geolocation information by zip code. 
-- The `dim_location` model selects relevant fields from the intermediate model and formats 
-- the `location_key` as a string for consistency in the data warehouse.

WITH geolocation AS (

    SELECT
        geolocation_zip_code_prefix,
        geolocation_city,
        geolocation_state,
        avg_geolocation_lat,
        avg_geolocation_lng,
        source_row_count,
        latest_updated_at

    FROM {{ ref('int_geolocation_by_zip') }}

)

SELECT
    CAST(geolocation_zip_code_prefix AS STRING) AS location_key,

    geolocation_zip_code_prefix,
    geolocation_city,
    geolocation_state,
    avg_geolocation_lat,
    avg_geolocation_lng,
    source_row_count,
    latest_updated_at

FROM geolocation