TRUNCATE TABLE raw.olist_orders;

SELECT COUNT(*) FROM raw.olist_orders;

SELECT COUNT(*)
FROM raw.olist_orders
WHERE order_id = 'order_id';

SELECT
    COUNT(*) AS total_rows,
    COUNT(*) FILTER (WHERE order_id = 'order_id') AS header_rows
FROM raw.olist_orders;

SELECT
    COUNT(*) AS total_rows,
    COUNT(*) FILTER (WHERE order_id = 'order_id') AS header_rows
FROM raw.olist_order_items;

SELECT
    COUNT(*) AS total_rows,
    COUNT(*) FILTER (WHERE product_id = 'product_id') AS header_rows
FROM raw.olist_products;

SELECT
    COUNT(*) AS total_rows,
    COUNT(*) FILTER (WHERE seller_id = 'seller_id') AS header_rows
FROM raw.olist_sellers;

SELECT
    COUNT(*) AS total_rows,
    COUNT(*) FILTER (WHERE customer_id = 'customer_id') AS header_rows
FROM raw.olist_customers;

SELECT
    COUNT(*) AS total_rows,
    COUNT(*) FILTER (WHERE order_id = 'order_id') AS header_rows
FROM raw.olist_order_payments;

SELECT
    COUNT(*) AS total_rows,
    COUNT(*) FILTER (WHERE review_id = 'review_id') AS header_rows
FROM raw.olist_order_reviews;

SELECT
    COUNT(*) AS total_rows,
    COUNT(*) FILTER (
        WHERE geolocation_zip_code_prefix = 'geolocation_zip_code_prefix'
    ) AS header_rows
FROM raw.olist_geolocation;

SELECT
    COUNT(*) AS total_rows,
    COUNT(*) FILTER (
        WHERE product_category_name = 'product_category_name'
    ) AS header_rows
FROM raw.product_category_translation;

SELECT
    COUNT(*) AS total_rows,
    COUNT(*) FILTER (WHERE sku = 'sku') AS header_rows
FROM raw.clu_train;

SELECT
    COUNT(*) AS total_rows,
    COUNT(*) FILTER (WHERE sku = 'sku') AS header_rows
FROM raw.clu_test;


-- Phase 2: Verify all 11 raw table imports

WITH row_counts AS (
    SELECT 'olist_orders' AS table_name, 99441 AS expected,
           COUNT(*) AS actual FROM raw.olist_orders
    UNION ALL
    SELECT 'olist_order_items', 112650, COUNT(*) FROM raw.olist_order_items
    UNION ALL
    SELECT 'olist_products', 32951, COUNT(*) FROM raw.olist_products
    UNION ALL
    SELECT 'olist_sellers', 3095, COUNT(*) FROM raw.olist_sellers
    UNION ALL
    SELECT 'olist_customers', 99441, COUNT(*) FROM raw.olist_customers
    UNION ALL
    SELECT 'olist_order_payments', 103886, COUNT(*) FROM raw.olist_order_payments
    UNION ALL
    SELECT 'olist_order_reviews', 99224, COUNT(*) FROM raw.olist_order_reviews
    UNION ALL
    SELECT 'olist_geolocation', 1000163, COUNT(*) FROM raw.olist_geolocation
    UNION ALL
    SELECT 'product_category_translation', 71, COUNT(*) FROM raw.product_category_translation
    UNION ALL
    SELECT 'clu_train', 15243, COUNT(*) FROM raw.clu_train
    UNION ALL
    SELECT 'clu_test', 3810, COUNT(*) FROM raw.clu_test
)
SELECT
    table_name,
    expected,
    actual,
    actual - expected AS difference,
    CASE
        WHEN actual = expected THEN 'PASS'
        ELSE 'FAIL'
    END AS status
FROM row_counts
ORDER BY table_name;
