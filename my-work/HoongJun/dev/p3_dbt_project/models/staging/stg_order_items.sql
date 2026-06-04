-- Staging: order_items. Cast ids/money/date, drop Singer metadata, dedupe on (order_id, order_item_id).
-- Grain = one row per item line within an order. View, reads raw via source().

with source as (
    select * from {{ source('bronze', 'order_items') }}
),

renamed as (
    select
        order_id,
        safe_cast(order_item_id     as int64)     as order_item_id,
        product_id,
        seller_id,
        safe_cast(shipping_limit_date as timestamp) as shipping_limit_at,
        safe_cast(price             as numeric)   as price,
        safe_cast(freight_value     as numeric)   as freight_value,
        _sdc_sequence
    from source
)

select * except (_sdc_sequence)
from renamed
qualify row_number() over (partition by order_id, order_item_id order by _sdc_sequence desc) = 1
