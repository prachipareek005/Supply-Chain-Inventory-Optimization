
-- Phase 2, Step 4
-- Action 4.1: Verify PostgreSQL schemas

SELECT
    schema_name,

    CASE
        WHEN schema_name = 'raw'
            THEN 'Source data'

        WHEN schema_name = 'clean'
            THEN 'Cleaned and validated data'

        WHEN schema_name = 'mart'
            THEN 'Analytics and Power BI tables'

        WHEN schema_name = 'qa'
            THEN 'Quality assurance'

    END AS schema_purpose

FROM information_schema.schemata

WHERE schema_name IN (
    'raw',
    'clean',
    'mart',
    'qa'
)

ORDER BY schema_name;


-- Action 4.2: Validate Olist analytics table grain

WITH order_checks AS (
    SELECT
        COUNT(*) AS total_orders,
        COUNT(DISTINCT order_id) AS unique_orders
    FROM clean.olist_orders
),

item_checks AS (
    SELECT
        COUNT(*) AS total_order_items,
        COUNT(DISTINCT (order_id, order_item_id))
            AS unique_order_item_keys,
        COUNT(DISTINCT order_id)
            AS orders_with_items
    FROM clean.olist_order_items
)

SELECT
    o.total_orders,
    o.unique_orders,

    i.total_order_items,
    i.unique_order_item_keys,

    i.orders_with_items,

    o.total_orders - o.unique_orders
        AS duplicate_order_ids,

    i.total_order_items - i.unique_order_item_keys
        AS duplicate_order_item_keys

FROM order_checks o
CROSS JOIN item_checks i;
