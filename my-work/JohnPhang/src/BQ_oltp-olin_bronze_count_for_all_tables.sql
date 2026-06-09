SELECT 'oltp_olist_customers' AS table_name, COUNT(*) AS row_count
FROM `sctp-team2-project2-elt.olin_bronze.oltp_olist_customers`

UNION ALL
SELECT 'oltp_olist_geolocation' AS table_name, COUNT(*) AS row_count
FROM `sctp-team2-project2-elt.olin_bronze.oltp_olist_geolocation`

UNION ALL
SELECT 'oltp_olist_orders' AS table_name, COUNT(*) AS row_count
FROM `sctp-team2-project2-elt.olin_bronze.oltp_olist_orders`

UNION ALL
SELECT 'oltp_olist_order_items' AS table_name, COUNT(*) AS row_count
FROM `sctp-team2-project2-elt.olin_bronze.oltp_olist_order_items`

UNION ALL
SELECT 'oltp_olist_order_payments' AS table_name, COUNT(*) AS row_count
FROM `sctp-team2-project2-elt.olin_bronze.oltp_olist_order_payments`

UNION ALL
SELECT 'oltp_olist_order_reviews' AS table_name, COUNT(*) AS row_count
FROM `sctp-team2-project2-elt.olin_bronze.oltp_olist_order_reviews`

UNION ALL
SELECT 'oltp_olist_products' AS table_name, COUNT(*) AS row_count
FROM `sctp-team2-project2-elt.olin_bronze.oltp_olist_products`

UNION ALL
SELECT 'oltp_olist_sellers' AS table_name, COUNT(*) AS row_count
FROM `sctp-team2-project2-elt.olin_bronze.oltp_olist_sellers`

UNION ALL
SELECT 'oltp_product_category_name_translation' AS table_name, COUNT(*) AS row_count
FROM `sctp-team2-project2-elt.olin_bronze.oltp_product_category_name_translation`

ORDER BY table_name;