WITH sku_audit AS (
    SELECT
        sku,
        COUNT(*) AS occurrence_count,
        COUNT(DISTINCT dataset_source) AS source_count,
        COUNT(DISTINCT went_on_backorder)
            AS distinct_known_labels
    FROM mart.fact_inventory
    GROUP BY sku
)
SELECT
    COUNT(*) AS total_unique_skus,
    COUNT(*) FILTER (
        WHERE occurrence_count > 1
    ) AS duplicate_skus,
    COUNT(*) FILTER (
        WHERE source_count > 1
    ) AS train_test_overlap_skus,
    COUNT(*) FILTER (
        WHERE distinct_known_labels > 1
    ) AS conflicting_label_skus
FROM sku_audit;