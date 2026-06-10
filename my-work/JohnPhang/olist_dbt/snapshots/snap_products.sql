{% snapshot snap_products %}

-- This snapshot captures the history of products using SCD Type 2.
-- Each time a product record is updated, a new version is created in this snapshot with the updated_at timestamp. 
-- The dbt_valid_to field is used to indicate the end of validity for the previous version of the product record. 
-- When a product record is deleted, the is_deleted flag is set to TRUE, 
-- and the dbt_valid_to field is updated to indicate the end of validity for that record.

{{
    config(
        target_schema='snapshots',
        unique_key='product_id',
        strategy='timestamp',
        updated_at='updated_at',
        invalidate_hard_deletes=True
    )
}}

SELECT
    product_id,
    product_category_name,
    product_name_lenght,
    product_description_lenght,
    product_photos_qty,
    product_weight_g,
    product_length_cm,
    product_height_cm,
    product_width_cm,

    created_at,
    updated_at,
    is_deleted,
    source_file,
    source_gcs_path,
    batch_name

FROM {{ source('olist_bronze', 'oltp_olist_products') }}

{% endsnapshot %}