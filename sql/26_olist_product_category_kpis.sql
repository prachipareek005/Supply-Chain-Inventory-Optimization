
-- Phase 2, Step 4
-- Action 4.13: Product Category Performance

CREATE OR REPLACE VIEW mart.kpi_product_category AS

SELECT
    category_display_name,

    COUNT(*) AS total_items,

    COUNT(DISTINCT order_id) AS distinct_orders,

    COUNT(DISTINCT product_id) AS distinct_products,

    COUNT(DISTINCT seller_id) AS active_sellers,

    ROUND(
        SUM(item_sales_value), 2
    ) AS total_item_sales,

    ROUND(
        SUM(freight_value), 2
    ) AS total_freight,

    ROUND(
        SUM(item_total_value), 2
    ) AS total_item_value,

    ROUND(
        AVG(item_sales_value), 2
    ) AS avg_item_price,

    ROUND(
        SUM(freight_value)
        / NULLIF(SUM(item_sales_value), 0) * 100,
        2
    ) AS freight_to_sales_pct,

    ROUND(
        100.0 * SUM(item_sales_value)
        / NULLIF(
            SUM(SUM(item_sales_value)) OVER (), 0
        ),
        2
    ) AS sales_contribution_pct

FROM mart.fact_order_items

GROUP BY category_display_name;


-- Action 4.13: Verify Product Category Performance

SELECT
    COUNT(*) AS total_category_groups,

    SUM(total_items) AS total_items,

    ROUND(SUM(total_item_sales), 2)
        AS total_item_sales,

    ROUND(SUM(total_freight), 2)
        AS total_freight,

    COUNT(*) FILTER (
        WHERE category_display_name IS NULL
           OR TRIM(category_display_name) = ''
    ) AS missing_category_labels

FROM mart.kpi_product_category;


-- Preview top 10 product categories by sales

SELECT
    category_display_name,
    total_items,
    distinct_orders,
    total_item_sales,
    total_freight,
    freight_to_sales_pct,
    sales_contribution_pct

FROM mart.kpi_product_category

ORDER BY total_item_sales DESC

LIMIT 10;
