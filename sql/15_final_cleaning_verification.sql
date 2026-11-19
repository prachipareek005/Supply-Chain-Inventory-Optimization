
-- Action 3.63: Final cleaning verification
-- Compare all 11 raw and cleaned datasets

WITH table_counts AS (

    SELECT 'Olist Orders' AS dataset,
        (SELECT COUNT(*) FROM raw.olist_orders) AS raw_rows,
        (SELECT COUNT(*) FROM clean.olist_orders) AS clean_rows

    UNION ALL
    SELECT 'Olist Order Items',
        (SELECT COUNT(*) FROM raw.olist_order_items),
        (SELECT COUNT(*) FROM clean.olist_order_items)

    UNION ALL
    SELECT 'Olist Products',
        (SELECT COUNT(*) FROM raw.olist_products),
        (SELECT COUNT(*) FROM clean.olist_products)

    UNION ALL
    SELECT 'Olist Sellers',
        (SELECT COUNT(*) FROM raw.olist_sellers),
        (SELECT COUNT(*) FROM clean.olist_sellers)

    UNION ALL
    SELECT 'Olist Customers',
        (SELECT COUNT(*) FROM raw.olist_customers),
        (SELECT COUNT(*) FROM clean.olist_customers)

    UNION ALL
    SELECT 'Olist Payments',
        (SELECT COUNT(*) FROM raw.olist_order_payments),
        (SELECT COUNT(*) FROM clean.olist_order_payments)

    UNION ALL
    SELECT 'Olist Reviews',
        (SELECT COUNT(*) FROM raw.olist_order_reviews),
        (SELECT COUNT(*) FROM clean.olist_order_reviews)

    UNION ALL
    SELECT 'Olist Geolocation',
        (SELECT COUNT(*) FROM raw.olist_geolocation),
        (SELECT COUNT(*) FROM clean.olist_geolocation)

    UNION ALL
    SELECT 'Category Translation',
        (SELECT COUNT(*) FROM raw.product_category_translation),
        (SELECT COUNT(*) FROM clean.product_category_translation)

    UNION ALL
    SELECT 'CLU Training',
        (SELECT COUNT(*) FROM raw.clu_train),
        (SELECT COUNT(*) FROM clean.clu_train)

    UNION ALL
    SELECT 'CLU Test',
        (SELECT COUNT(*) FROM raw.clu_test),
        (SELECT COUNT(*) FROM clean.clu_test)
)

SELECT
    dataset,
    raw_rows,
    clean_rows,
    clean_rows - raw_rows AS row_difference,
    CASE
        WHEN raw_rows = clean_rows THEN 'PASS'
        ELSE 'FAIL'
    END AS verification_status

FROM table_counts
ORDER BY dataset;
