-- Staging: customers. Drop Singer (_sdc_*) metadata, dedupe on customer_id.
-- zip kept as STRING (it's an identifier code, leading zeros matter). View, reads raw via source().

with source as (
    select * from {{ source('bronze', 'customers') }}
),

renamed as (
    select
        customer_id,
        customer_unique_id,
        customer_zip_code_prefix,
        customer_city,
        customer_state,
        _sdc_sequence
    from source
)

select * except (_sdc_sequence)
from renamed
qualify row_number() over (partition by customer_id order by _sdc_sequence desc) = 1
