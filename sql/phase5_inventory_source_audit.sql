SELECT
    dataset_source,
    went_on_backorder,
    COUNT(*) AS row_count,
    COUNT(DISTINCT sku) AS unique_skus
FROM mart.fact_inventory
GROUP BY
    dataset_source,
    went_on_backorder
ORDER BY
    dataset_source,
    went_on_backorder;