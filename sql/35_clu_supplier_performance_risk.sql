
-- Phase 2, Step 4
-- Action 4.22: Supplier Performance Risk Patterns

CREATE OR REPLACE VIEW
mart.kpi_supplier_performance_risk AS

WITH benchmark AS (
    SELECT
        100.0 * COUNT(*) FILTER (
            WHERE went_on_backorder = TRUE
        ) / NULLIF(COUNT(*), 0)
            AS overall_backorder_rate_pct

    FROM mart.fact_inventory

    WHERE dataset_source = 'train'
      AND went_on_backorder IS NOT NULL
),

performance_comparison AS (
    SELECT
        p.performance_period,
        p.performance_category,

        p.total_skus,
        p.backorder_skus,
        p.non_backorder_skus,

        p.backorder_rate_pct,
        p.avg_performance_score,

        ROUND(
            b.overall_backorder_rate_pct,
            2
        ) AS benchmark_backorder_rate_pct,

        ROUND(
            p.backorder_rate_pct
            - b.overall_backorder_rate_pct,
            2
        ) AS difference_from_benchmark_pp,

        ROUND(
            p.backorder_rate_pct
            / NULLIF(
                b.overall_backorder_rate_pct,
                0
            ),
            2
        ) AS relative_backorder_risk

    FROM mart.kpi_backorders_by_supplier_performance p

    CROSS JOIN benchmark b
)

SELECT
    *,

    CASE
        WHEN total_skus < 30
            THEN 'Insufficient Sample'

        WHEN backorder_rate_pct >=
             benchmark_backorder_rate_pct * 1.5
            THEN 'High'

        WHEN backorder_rate_pct >
             benchmark_backorder_rate_pct
            THEN 'Above Benchmark'

        ELSE 'At or Below Benchmark'
    END AS performance_risk_category

FROM performance_comparison;


-- Action 4.22: Verify Supplier Performance Risk

SELECT
    performance_period,

    COUNT(*) AS total_groups,

    SUM(total_skus) AS total_skus,

    SUM(backorder_skus) AS total_backorders,

    COUNT(*) FILTER (
        WHERE performance_risk_category = 'High'
    ) AS high_risk_groups,

    COUNT(*) FILTER (
        WHERE performance_risk_category = 'Above Benchmark'
    ) AS above_benchmark_groups,

    COUNT(*) FILTER (
        WHERE performance_risk_category = 'At or Below Benchmark'
    ) AS at_or_below_groups,

    COUNT(*) FILTER (
        WHERE performance_risk_category = 'Insufficient Sample'
    ) AS insufficient_sample_groups,

    COUNT(*) FILTER (
        WHERE performance_risk_category IS NULL
    ) AS unclassified_groups

FROM mart.kpi_supplier_performance_risk

GROUP BY performance_period

ORDER BY performance_period;


-- Preview Supplier Performance Risk Patterns

SELECT
    performance_period,
    performance_category,
    total_skus,
    backorder_skus,
    backorder_rate_pct,
    benchmark_backorder_rate_pct,
    difference_from_benchmark_pp,
    relative_backorder_risk,
    performance_risk_category

FROM mart.kpi_supplier_performance_risk

ORDER BY
    performance_period,
    backorder_rate_pct DESC;
