-- Phase 5 - Action 5.4.6
-- Verify imported prediction counts

SELECT
    COUNT(*) AS total_predictions,
    COUNT(DISTINCT sku) AS unique_skus,
    SUM(predicted_backorder_flag) AS flagged_skus,
    COUNT(*) FILTER (
        WHERE predicted_backorder_flag = 0
    ) AS not_flagged_skus
FROM mart.sku_backorder_predictions;



-- Verify imported risk distribution

SELECT
    risk_category,
    COUNT(*) AS sku_count,
    ROUND(
        COUNT(*) * 100.0 /
        SUM(COUNT(*)) OVER (),
        2
    ) AS percentage
FROM mart.sku_backorder_predictions
GROUP BY risk_category
ORDER BY
    CASE risk_category
        WHEN 'Low' THEN 1
        WHEN 'Medium' THEN 2
        WHEN 'High' THEN 3
    END;



-- Verify prediction-to-inventory SKU matching

SELECT
    COUNT(*) AS prediction_rows,
    COUNT(i.sku) AS matched_inventory_skus,
    COUNT(*) FILTER (
        WHERE i.sku IS NULL
    ) AS unmatched_skus,
    COUNT(*) FILTER (
        WHERE i.dataset_source = 'test'
    ) AS matched_test_skus,
    COUNT(*) FILTER (
        WHERE i.dataset_source = 'train'
    ) AS matched_train_skus
FROM mart.sku_backorder_predictions p
LEFT JOIN mart.fact_inventory i
    ON p.sku = i.sku;



-- Confirm historical inventory was not modified

SELECT
    COUNT(*) AS total_inventory_rows,
    COUNT(DISTINCT sku) AS unique_inventory_skus,
    COUNT(*) FILTER (
        WHERE dataset_source = 'train'
    ) AS labelled_records,
    COUNT(*) FILTER (
        WHERE dataset_source = 'test'
    ) AS unlabelled_records,
    COUNT(*) FILTER (
        WHERE dataset_source = 'train'
          AND went_on_backorder = TRUE
    ) AS historical_backorders
FROM mart.fact_inventory;
