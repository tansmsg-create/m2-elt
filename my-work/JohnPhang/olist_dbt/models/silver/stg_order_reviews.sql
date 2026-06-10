SELECT
    review_id,
    order_id,
    review_score,

    review_comment_title,
    review_comment_message,

    CAST(review_creation_date AS TIMESTAMP) AS review_creation_date,
    CAST(review_answer_timestamp AS TIMESTAMP) AS review_answer_timestamp,

    CASE
        WHEN review_comment_message IS NOT NULL
             AND TRIM(review_comment_message) != ''
        THEN TRUE
        ELSE FALSE
    END AS has_review_comment,

    created_at,
    updated_at,
    is_deleted,
    source_file,
    source_gcs_path,
    batch_name

FROM {{ source('olist_bronze', 'oltp_olist_order_reviews') }}
WHERE COALESCE(is_deleted, FALSE) = FALSE