-- Staging: order_reviews. Cast score/timestamps, drop Singer metadata, dedupe on (review_id, order_id).
-- review_id can recur across orders in Olist, so grain is the (review_id, order_id) pair.

with source as (
    select * from {{ source('bronze', 'order_reviews') }}
),

renamed as (
    select
        review_id,
        order_id,
        safe_cast(review_score as int64)            as review_score,
        review_comment_title,
        review_comment_message,
        safe_cast(review_creation_date  as timestamp) as review_created_at,
        safe_cast(review_answer_timestamp as timestamp) as review_answered_at,
        _sdc_sequence
    from source
)

select * except (_sdc_sequence)
from renamed
qualify row_number() over (partition by review_id, order_id order by _sdc_sequence desc) = 1
