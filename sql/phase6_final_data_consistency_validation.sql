SELECT
    'Orders' AS dataset,
    COUNT(*) AS record_count
FROM mart.fact_orders

UNION ALL

SELECT
    'Order Items',
    COUNT(*)
FROM mart.fact_order_items

UNION ALL

SELECT
    'Inventory',
    COUNT(*)
FROM mart.fact_inventory

UNION ALL

SELECT
    'ML Predictions',
    COUNT(*)
FROM mart.sku_backorder_predictions;