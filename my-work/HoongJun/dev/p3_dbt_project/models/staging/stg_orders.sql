-- Staging: orders. Cast string timestamps, drop Singer (_sdc_*) metadata, dedupe on order_id.
-- Materialized as a view (set at folder level in dbt_project.yml). Reads raw via source().
--
-- Dedupe rationale: the M1 EL loads in APPEND mode, so re-runs can land the same order_id
-- more than once. Keep the latest copy per order_id by _sdc_sequence (Singer load order).
-- (0 dupes today — this is a forward guard against re-runs, validated by the unique test in _stg.yml.)

with source as (
    select * from {{ source('bronze', 'orders') }}
),

renamed as (
    select
        order_id,
        customer_id,
        order_status,
        safe_cast(order_purchase_timestamp      as timestamp) as order_purchased_at,
        safe_cast(order_approved_at             as timestamp) as order_approved_at,
        safe_cast(order_delivered_carrier_date  as timestamp) as order_delivered_to_carrier_at,
        safe_cast(order_delivered_customer_date as timestamp) as order_delivered_at,
        safe_cast(order_estimated_delivery_date as timestamp) as order_estimated_delivery_at,
        _sdc_sequence
    from source
)

select * except (_sdc_sequence)
from renamed
qualify row_number() over (partition by order_id order by _sdc_sequence desc) = 1
