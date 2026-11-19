
-- Phase 2, Step 4
-- Action 4.14: Final Olist Analytics Reconciliation

WITH checks AS (

    SELECT 'Order rows' AS check_name,
        (SELECT COUNT(*)::NUMERIC
         FROM mart.fact_orders) AS actual_value,
        99441::NUMERIC AS expected_value

    UNION ALL
    SELECT 'Order-level financial rows',
        (SELECT COUNT(*)::NUMERIC
         FROM mart.order_financial_summary),
        99441::NUMERIC

    UNION ALL
    SELECT 'Order-item rows',
        (SELECT COUNT(*)::NUMERIC
         FROM mart.fact_order_items),
        112650::NUMERIC

    UNION ALL
    SELECT 'Aggregated item count',
        (SELECT SUM(item_count)::NUMERIC
         FROM mart.order_financial_summary),
        112650::NUMERIC

    UNION ALL
    SELECT 'Regional order total',
        (SELECT SUM(total_orders)::NUMERIC
         FROM mart.kpi_delivery_by_state),
        99441::NUMERIC

    UNION ALL
    SELECT 'Monthly order total',
        (SELECT SUM(total_orders)::NUMERIC
         FROM mart.kpi_delivery_by_month),
        99441::NUMERIC

    UNION ALL
    SELECT 'Eligible deliveries',
        (SELECT eligible_deliveries::NUMERIC
         FROM mart.kpi_delivery_performance),
        96470::NUMERIC

    UNION ALL
    SELECT 'Late deliveries',
        (SELECT late_deliveries::NUMERIC
         FROM mart.kpi_delivery_performance),
        6534::NUMERIC

    UNION ALL
    SELECT 'Seller count',
        (SELECT COUNT(*)::NUMERIC
         FROM mart.kpi_seller_fulfillment),
        3095::NUMERIC

    UNION ALL
    SELECT 'Seller item total',
        (SELECT SUM(total_items)::NUMERIC
         FROM mart.kpi_seller_fulfillment),
        112650::NUMERIC

    UNION ALL
    SELECT 'Freight view item total',
        (SELECT SUM(total_items)::NUMERIC
         FROM mart.kpi_shipping_freight),
        112650::NUMERIC

    UNION ALL
    SELECT 'Category view item total',
        (SELECT SUM(total_items)::NUMERIC
         FROM mart.kpi_product_category),
        112650::NUMERIC

    UNION ALL
    SELECT 'Order-level item sales',
        (SELECT ROUND(SUM(total_item_sales), 2)
         FROM mart.order_financial_summary),
        13591643.70::NUMERIC

    UNION ALL
    SELECT 'Category-level item sales',
        (SELECT ROUND(SUM(total_item_sales), 2)
         FROM mart.kpi_product_category),
        13591643.70::NUMERIC

    UNION ALL
    SELECT 'Order-level freight',
        (SELECT ROUND(SUM(total_freight), 2)
         FROM mart.order_financial_summary),
        2251909.54::NUMERIC

    UNION ALL
    SELECT 'Category-level freight',
        (SELECT ROUND(SUM(total_freight), 2)
         FROM mart.kpi_product_category),
        2251909.54::NUMERIC
)

SELECT
    check_name,
    actual_value,
    expected_value,

    actual_value - expected_value AS difference,

    CASE
        WHEN actual_value = expected_value
        THEN 'PASS'
        ELSE 'FAIL'
    END AS verification_status

FROM checks
ORDER BY check_name;
