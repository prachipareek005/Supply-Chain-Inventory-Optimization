
-- Phase 2, Step 4
-- Action 4.15: Validate CLU Inventory Analytics Grain

WITH train_checks AS (
    SELECT
        COUNT(*) AS total_records,
        COUNT(DISTINCT sku) AS unique_skus,
        COUNT(*) FILTER (
            WHERE went_on_backorder IS NULL
        ) AS missing_target_labels
    FROM clean.clu_train
),

test_checks AS (
    SELECT
        COUNT(*) AS total_records,
        COUNT(DISTINCT sku) AS unique_skus
    FROM clean.clu_test
),

overlap_check AS (
    SELECT
        COUNT(*) AS overlapping_skus
    FROM clean.clu_test t
    WHERE EXISTS (
        SELECT 1
        FROM clean.clu_train tr
        WHERE tr.sku = t.sku
    )
)

SELECT
    tr.total_records AS train_records,
    tr.unique_skus AS unique_train_skus,

    te.total_records AS test_records,
    te.unique_skus AS unique_test_skus,

    tr.total_records + te.total_records
        AS combined_records,

    tr.missing_target_labels,

    o.overlapping_skus

FROM train_checks tr
CROSS JOIN test_checks te
CROSS JOIN overlap_check o;
