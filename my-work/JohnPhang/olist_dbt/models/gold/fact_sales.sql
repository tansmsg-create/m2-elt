{{ config(materialized='table') }}

-- Grain: one row per order item. That means each row represents a product item sold within an order, not just one row per order.
-- This allows for detailed analysis at the order-item level, such as analyzing sales performance of individual products, 
-- understanding customer purchasing behavior at a granular level, and evaluating delivery performance for each item.
-- fact_sales table supports order-item level sales analysis, revenue analysis, delivery performance analysis, 
-- and customer satisfaction analysis.


WITH order_items AS (

    SELECT
        order_id,
        order_item_id,
        product_id,
        seller_id,
        shipping_limit_date,
        price,
        freight_value,
        price + freight_value AS item_total_amount,
        updated_at AS order_item_updated_at

    FROM {{ ref('stg_order_items') }}

),

orders AS (

    SELECT
        order_id,
        customer_id,
        order_status,
        order_purchase_timestamp,
        order_approved_at,
        order_delivered_carrier_date,
        order_delivered_customer_date,
        order_estimated_delivery_date,
        updated_at AS order_updated_at

    FROM {{ ref('stg_orders') }}

),

payments_aggregated AS (

    SELECT
        order_id,
        COUNT(*) AS payment_record_count,
        SUM(payment_value) AS total_payment_value,
        MAX(payment_installments) AS max_payment_installments,
        STRING_AGG(DISTINCT payment_type, ', ') AS payment_types,
        MAX(updated_at) AS payment_updated_at

    FROM {{ ref('stg_order_payments') }}

    GROUP BY order_id

),

reviews_aggregated AS (

    SELECT
        order_id,
        COUNT(*) AS review_record_count,
        AVG(review_score) AS avg_review_score,
        MAX(review_score) AS max_review_score,
        MIN(review_score) AS min_review_score,
        MAX(has_review_comment) AS has_review_comment,
        MAX(review_creation_date) AS latest_review_creation_date,
        MAX(review_answer_timestamp) AS latest_review_answer_timestamp,
        MAX(updated_at) AS review_updated_at

    FROM {{ ref('stg_order_reviews') }}

    GROUP BY order_id

),

base_sales AS (

    SELECT
        oi.order_id,
        oi.order_item_id,

        o.customer_id,
        oi.product_id,
        oi.seller_id,

        o.order_status,

        oi.shipping_limit_date,
        o.order_purchase_timestamp,
        o.order_approved_at,
        o.order_delivered_carrier_date,
        o.order_delivered_customer_date,
        o.order_estimated_delivery_date,

        DATE(o.order_purchase_timestamp) AS purchase_date,
        DATE(o.order_approved_at) AS approved_date,
        DATE(o.order_delivered_customer_date) AS delivered_customer_date,
        DATE(o.order_estimated_delivery_date) AS estimated_delivery_date,

        CASE
            WHEN o.order_purchase_timestamp IS NOT NULL
            THEN CAST(FORMAT_DATE('%Y%m%d', DATE(o.order_purchase_timestamp)) AS INT64)
            ELSE NULL
        END AS purchase_date_key,

        CASE
            WHEN o.order_approved_at IS NOT NULL
            THEN CAST(FORMAT_DATE('%Y%m%d', DATE(o.order_approved_at)) AS INT64)
            ELSE NULL
        END AS approved_date_key,

        CASE
            WHEN o.order_delivered_customer_date IS NOT NULL
            THEN CAST(FORMAT_DATE('%Y%m%d', DATE(o.order_delivered_customer_date)) AS INT64)
            ELSE NULL
        END AS delivered_customer_date_key,

        CASE
            WHEN o.order_estimated_delivery_date IS NOT NULL
            THEN CAST(FORMAT_DATE('%Y%m%d', DATE(o.order_estimated_delivery_date)) AS INT64)
            ELSE NULL
        END AS estimated_delivery_date_key,

        oi.price,
        oi.freight_value,
        oi.item_total_amount,

        SUM(oi.item_total_amount) OVER (
            PARTITION BY oi.order_id
        ) AS order_items_total_amount,

        p.payment_record_count,
        p.total_payment_value,
        p.max_payment_installments,
        p.payment_types,

        r.review_record_count,
        r.avg_review_score,
        r.max_review_score,
        r.min_review_score,
        r.has_review_comment,
        r.latest_review_creation_date,
        r.latest_review_answer_timestamp,

        CASE
            WHEN o.order_delivered_customer_date IS NOT NULL
             AND o.order_purchase_timestamp IS NOT NULL
            THEN DATE_DIFF(
                DATE(o.order_delivered_customer_date),
                DATE(o.order_purchase_timestamp),
                DAY
            )
            ELSE NULL
        END AS delivery_days,

        CASE
            WHEN o.order_delivered_customer_date IS NOT NULL
             AND o.order_estimated_delivery_date IS NOT NULL
            THEN DATE_DIFF(
                DATE(o.order_delivered_customer_date),
                DATE(o.order_estimated_delivery_date),
                DAY
            )
            ELSE NULL
        END AS delivery_delay_days,

        CASE
            WHEN o.order_delivered_customer_date IS NOT NULL
             AND o.order_estimated_delivery_date IS NOT NULL
             AND o.order_delivered_customer_date > o.order_estimated_delivery_date
            THEN TRUE
            WHEN o.order_delivered_customer_date IS NOT NULL
             AND o.order_estimated_delivery_date IS NOT NULL
            THEN FALSE
            ELSE NULL
        END AS is_late_delivery,

        GREATEST(
            COALESCE(oi.order_item_updated_at, TIMESTAMP '1900-01-01 00:00:00 UTC'),
            COALESCE(o.order_updated_at, TIMESTAMP '1900-01-01 00:00:00 UTC'),
            COALESCE(p.payment_updated_at, TIMESTAMP '1900-01-01 00:00:00 UTC'),
            COALESCE(r.review_updated_at, TIMESTAMP '1900-01-01 00:00:00 UTC')
        ) AS latest_updated_at

    FROM order_items oi

    INNER JOIN orders o
        ON oi.order_id = o.order_id

    LEFT JOIN payments_aggregated p
        ON oi.order_id = p.order_id

    LEFT JOIN reviews_aggregated r
        ON oi.order_id = r.order_id

)

SELECT
    TO_HEX(MD5(CONCAT(order_id, '-', CAST(order_item_id AS STRING)))) AS sales_key,

    order_id,
    order_item_id,

    customer_id AS customer_key,
    product_id AS product_key,
    seller_id AS seller_key,

    purchase_date_key,
    approved_date_key,
    delivered_customer_date_key,
    estimated_delivery_date_key,

    customer_id,
    product_id,
    seller_id,

    order_status,

    purchase_date,
    approved_date,
    delivered_customer_date,
    estimated_delivery_date,

    order_purchase_timestamp,
    order_approved_at,
    order_delivered_carrier_date,
    order_delivered_customer_date,
    order_estimated_delivery_date,
    shipping_limit_date,

    price,
    freight_value,
    item_total_amount AS total_sale_amount,

    payment_record_count,
    total_payment_value,

    CASE
        WHEN order_items_total_amount > 0
        THEN total_payment_value * item_total_amount / order_items_total_amount
        ELSE NULL
    END AS allocated_payment_value,

    max_payment_installments,
    payment_types,

    review_record_count,
    avg_review_score,
    max_review_score,
    min_review_score,
    has_review_comment,
    latest_review_creation_date,
    latest_review_answer_timestamp,

    delivery_days,
    delivery_delay_days,
    is_late_delivery,

    latest_updated_at

FROM base_sales