
-- Phase 2, Step 4
-- Action 4.5: Create Order-Level Financial Summary

CREATE OR REPLACE VIEW mart.order_financial_summary AS

WITH item_totals AS (
    SELECT
        order_id,

        COUNT(*) AS item_count,

        SUM(item_sales_value) AS total_item_sales,

        SUM(freight_value) AS total_freight,

        SUM(item_total_value) AS total_order_value

    FROM mart.fact_order_items

    GROUP BY order_id
)

SELECT
    o.order_id,

    o.customer_id,

    o.order_status,

    o.purchase_date,

    -- Preserve orders with no item records
    COALESCE(i.item_count, 0)
        AS item_count,

    COALESCE(i.total_item_sales, 0)
        AS total_item_sales,

    COALESCE(i.total_freight, 0)
        AS total_freight,

    COALESCE(i.total_order_value, 0)
        AS total_order_value,

    CASE
        WHEN i.order_id IS NULL
        THEN 1 ELSE 0
    END AS no_item_record_flag

FROM mart.fact_orders o

LEFT JOIN item_totals i
    ON o.order_id = i.order_id;


-- Action 4.5: Verify Order-Level Financial Summary

SELECT
    COUNT(*) AS total_orders,

    COUNT(DISTINCT order_id) AS unique_orders,

    COUNT(*) - COUNT(DISTINCT order_id)
        AS duplicate_order_ids,

    COALESCE(SUM(item_count), 0)
        AS total_order_items,

    COALESCE(SUM(no_item_record_flag), 0)
        AS orders_without_items,

    COUNT(*) FILTER (
        WHERE total_item_sales < 0
           OR total_freight < 0
           OR total_order_value < 0
    ) AS negative_financial_totals

FROM mart.order_financial_summary;


-- Action 4.6: Reconcile Olist sales and freight totals

WITH raw_totals AS (
    SELECT
        SUM(price) AS sales,
        SUM(freight_value) AS freight
    FROM clean.olist_order_items
),

item_totals AS (
    SELECT
        SUM(item_sales_value) AS sales,
        SUM(freight_value) AS freight
    FROM mart.fact_order_items
),

order_totals AS (
    SELECT
        SUM(total_item_sales) AS sales,
        SUM(total_freight) AS freight
    FROM mart.order_financial_summary
)

SELECT
    ROUND(r.sales, 2) AS source_sales,
    ROUND(i.sales, 2) AS item_view_sales,
    ROUND(o.sales, 2) AS order_view_sales,

    ROUND(r.freight, 2) AS source_freight,
    ROUND(i.freight, 2) AS item_view_freight,
    ROUND(o.freight, 2) AS order_view_freight,

    ROUND(i.sales - r.sales, 2)
        AS item_sales_difference,

    ROUND(o.sales - r.sales, 2)
        AS order_sales_difference,

    ROUND(i.freight - r.freight, 2)
        AS item_freight_difference,

    ROUND(o.freight - r.freight, 2)
        AS order_freight_difference

FROM raw_totals r
CROSS JOIN item_totals i
CROSS JOIN order_totals o;
