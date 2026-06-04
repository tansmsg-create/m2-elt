-- Staging: order_payments. Cast numerics, drop Singer metadata, dedupe on (order_id, payment_sequential).
-- Grain = one row per payment record within an order. View, reads raw via source().

with source as (
    select * from {{ source('bronze', 'order_payments') }}
),

renamed as (
    select
        order_id,
        safe_cast(payment_sequential   as int64)   as payment_sequential,
        payment_type,
        safe_cast(payment_installments as int64)   as payment_installments,
        safe_cast(payment_value        as numeric) as payment_value,
        _sdc_sequence
    from source
)

select * except (_sdc_sequence)
from renamed
qualify row_number() over (partition by order_id, payment_sequential order by _sdc_sequence desc) = 1
