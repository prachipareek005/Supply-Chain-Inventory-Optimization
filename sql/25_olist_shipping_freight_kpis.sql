
-- Phase 2, Step 4
-- Action 4.12: Shipping and Freight Performance

CREATE OR REPLACE VIEW mart.kpi_shipping_freight AS

SELECT
    COALESCE(seller_state, 'UNKNOWN')
        AS seller_state,

    COUNT(*) AS total_items,

    COUNT(DISTINCT order_id)
        AS distinct_orders,

    COUNT(DISTINCT seller_id)
        AS active_sellers,

    ROUND(SUM(item_sales_value), 2)
        AS total_item_sales,

    ROUND(SUM(freight_value), 2)
        AS total_freight,

    ROUND(
        SUM(freight_value)
        / NULLIF(SUM(item_sales_value), 0) * 100,
        2
    ) AS freight_to_sales_pct,

    ROUND(
        AVG(freight_value),
        2
    ) AS avg_freight_per_item,

    ROUND(
        SUM(freight_value)
        / NULLIF(COUNT(DISTINCT order_id), 0),
        2
    ) AS freight_per_distinct_order

FROM mart.fact_order_items

GROUP BY COALESCE(seller_state, 'UNKNOWN');


-- Action 4.12: Verify Shipping & Freight KPIs

SELECT
    COUNT(*) AS total_state_groups,

    SUM(total_items) AS total_items,

    ROUND(SUM(total_item_sales), 2)
        AS total_item_sales,

    ROUND(SUM(total_freight), 2)
        AS total_freight,

    COUNT(*) FILTER (
        WHERE total_item_sales < 0
           OR total_freight < 0
    ) AS negative_total_groups

FROM mart.kpi_shipping_freight;


-- Preview seller states with high freight-to-sales ratios

SELECT
    seller_state,
    total_items,
    distinct_orders,
    total_item_sales,
    total_freight,
    freight_to_sales_pct,
    avg_freight_per_item

FROM mart.kpi_shipping_freight

WHERE total_items >= 100

ORDER BY freight_to_sales_pct DESC

LIMIT 10;
