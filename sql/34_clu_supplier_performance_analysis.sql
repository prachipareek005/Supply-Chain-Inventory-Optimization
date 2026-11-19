
-- Phase 2, Step 4
-- Action 4.21: Supplier Performance and Backorders

CREATE OR REPLACE VIEW
mart.kpi_backorders_by_supplier_performance AS

WITH performance_records AS (
    SELECT
        sku,
        went_on_backorder,
        '6-month' AS performance_period,
        perf_6_month_avg AS performance_score
    FROM mart.fact_inventory
    WHERE dataset_source = 'train'

    UNION ALL

    SELECT
        sku,
        went_on_backorder,
        '12-month' AS performance_period,
        perf_12_month_avg AS performance_score
    FROM mart.fact_inventory
    WHERE dataset_source = 'train'
),

performance_groups AS (
    SELECT
        *,
        CASE
            WHEN performance_score IS NULL
                THEN 'Unknown'

            WHEN performance_score < 0
              OR performance_score > 1
                THEN 'Out of Range'

            WHEN performance_score < 0.50
                THEN 'Below 0.50'

            WHEN performance_score < 0.80
                THEN '0.50–0.79'

            WHEN performance_score < 0.95
                THEN '0.80–0.94'

            ELSE '0.95–1.00'
        END AS performance_category

    FROM performance_records
)

SELECT
    performance_period,
    performance_category,

    COUNT(*) AS total_skus,

    COUNT(*) FILTER (
        WHERE went_on_backorder = TRUE
    ) AS backorder_skus,

    COUNT(*) FILTER (
        WHERE went_on_backorder = FALSE
    ) AS non_backorder_skus,

    ROUND(
        100.0 * COUNT(*) FILTER (
            WHERE went_on_backorder = TRUE
        ) / NULLIF(COUNT(*), 0),
        2
    ) AS backorder_rate_pct,

    ROUND(AVG(performance_score), 3)
        AS avg_performance_score

FROM performance_groups

GROUP BY
    performance_period,
    performance_category;


-- Action 4.21: Verify Supplier Performance Analysis

SELECT
    performance_period,

    COUNT(*) AS total_categories,

    SUM(total_skus) AS total_training_skus,

    SUM(backorder_skus) AS total_backorders,

    SUM(non_backorder_skus)
        AS total_non_backorders,

    ROUND(
        100.0 * SUM(backorder_skus)
        / NULLIF(SUM(total_skus), 0),
        2
    ) AS overall_backorder_rate_pct,

    COALESCE(
        SUM(total_skus) FILTER (
            WHERE performance_category = 'Unknown'
        ), 0
    ) AS unknown_performance_skus

FROM mart.kpi_backorders_by_supplier_performance

GROUP BY performance_period

ORDER BY performance_period;
