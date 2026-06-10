{% snapshot products_snapshot %}

{{
  config(
    target_schema='snapshots',
    unique_key='product_id',
    strategy='check',
    check_cols=[
      'product_category_name',
      'product_name_lenght',
      'product_description_lenght',
      'product_photos_qty',
      'product_weight_g',
      'product_length_cm',
      'product_height_cm',
      'product_width_cm'
    ]
  )
}}

WITH item AS (
    SELECT
        product_id,
        product_category_name,
        product_name_lenght,
        product_description_lenght,
        product_photos_qty,
        product_weight_g,
        product_length_cm,
        product_height_cm,
        product_width_cm
    FROM {{ source('brazil_ecommerce', 'olist_products_raw') }}
)

SELECT * FROM item

{% endsnapshot %}