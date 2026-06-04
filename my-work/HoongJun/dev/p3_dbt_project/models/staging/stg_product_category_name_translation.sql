-- Staging: product category PT->EN translation. Drop Singer metadata, dedupe on product_category_name.
-- Lookup table. View, reads raw via source().

with source as (
    select * from {{ source('bronze', 'product_category_name_translation') }}
),

renamed as (
    select
        product_category_name,
        product_category_name_english,
        _sdc_sequence
    from source
)

select * except (_sdc_sequence)
from renamed
qualify row_number() over (partition by product_category_name order by _sdc_sequence desc) = 1
