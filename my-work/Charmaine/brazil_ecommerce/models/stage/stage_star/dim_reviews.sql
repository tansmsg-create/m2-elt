SELECT 
    --review_id,
    order_id as id,
    --id,
    review_score,
    review_comment_title,
    review_comment_message,
    --review_creation_date,
    CAST(review_answer_timestamp AS TIMESTAMP) AS review_answer_timestamp
FROM {{ source('brazil_ecommerce', 'olist_order_reviews_dataset') }}
WHERE order_id IS NOT NULL
QUALIFY ROW_NUMBER() OVER (PARTITION BY id ORDER BY review_answer_timestamp DESC) = 1