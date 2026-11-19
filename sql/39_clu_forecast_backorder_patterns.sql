
-- Phase 2, Step 4
-- Action 4.26: Forecast Demand & Backorder Patterns

CREATE OR REPLACE VIEW
mart.kpi_backorders_by_forecast_category AS

WITH forecast_groups AS (
    SELECT
        f.dataset_source,
        f.forecast_category,

        f.total_skus,
        f.avg_forecast_3_month,
        f.avg_sales_3_month,
        f.avg_inventory

    FROM mart.kpi_forecast_vs_sales f

    WHERE f.dataset_source = 'train'
),

labeled_inventory AS (
    SELECT
        sku,
        forecast_3_month,
        sales_3_month,
        went_on_backorder,

        CASE
            WHEN forecast_3_month IS NULL
              OR sales_3_month IS NULL
              OR forecast_3_month < 0
              OR sales_3_month < 0
                THEN 'Unknown'

            WHEN sales_3_month = 0
                THEN 'Zero Historical Sales'

            WHEN forecast_3_month > sales_3_month * 1.10
                THEN 'Higher Forecast'

            WHEN forecast_3_month < sales_3_month * 0.90
                THEN 'Lower Forecast'

            ELSE 'Similar'
        END AS forecast_category

    FROM mart.inventory_demand_forecast

    WHERE dataset_source = 'train'
      AND went_on_backorder IS NOT NULL
),

backorder_summary AS (
    SELECT
        forecast_category,

        COUNT(*) AS labeled_skus,

        COUNT(*) FILTER (
            WHERE went_on_backorder = TRUE
        ) AS backorder_skus,

        COUNT(*) FILTER (
            WHERE went_on_backorder = FALSE
        ) AS non_backorder_skus

    FROM labeled_inventory

    GROUP BY forecast_category
),

benchmark AS (
    SELECT
        100.0 * COUNT(*) FILTER (
            WHERE went_on_backorder = TRUE
        ) / NULLIF(COUNT(*), 0)
            AS overall_backorder_rate_pct

    FROM mart.fact_inventory

    WHERE dataset_source = 'train'
      AND went_on_backorder IS NOT NULL
)

SELECT
    f.forecast_category,

    f.total_skus,
    b.labeled_skus,
    b.backorder_skus,
    b.non_backorder_skus,

    ROUND(
        100.0 * b.backorder_skus
        / NULLIF(b.labeled_skus, 0),
        2
    ) AS backorder_rate_pct,

    ROUND(
        benchmark.overall_backorder_rate_pct,
        2
    ) AS benchmark_backorder_rate_pct,

    ROUND(
        100.0 * b.backorder_skus
        / NULLIF(b.labeled_skus, 0)
        - benchmark.overall_backorder_rate_pct,
        2
    ) AS difference_from_benchmark_pp,

    f.avg_forecast_3_month,
    f.avg_sales_3_month,
    f.avg_inventory

FROM forecast_groups f

JOIN backorder_summary b
    ON f.forecast_category = b.forecast_category

CROSS JOIN benchmark;


-- Action 4.26: Verify Forecast & Backorder Patterns

SELECT
    COUNT(*) AS total_forecast_categories,

    SUM(total_skus) AS total_training_skus,

    SUM(labeled_skus) AS total_labeled_skus,

    SUM(backorder_skus) AS total_backorders,

    SUM(non_backorder_skus) AS total_non_backorders,

    ROUND(
        100.0 * SUM(backorder_skus)
        / NULLIF(SUM(labeled_skus), 0),
        2
    ) AS overall_backorder_rate_pct,

    COUNT(*) FILTER (
        WHERE total_skus <> labeled_skus
    ) AS mismatched_category_counts

FROM mart.kpi_backorders_by_forecast_category;


-- Preview historical backorder rates
-- by forecast-demand category

SELECT
    forecast_category,
    total_skus,
    backorder_skus,
    non_backorder_skus,
    backorder_rate_pct,
    benchmark_backorder_rate_pct,
    difference_from_benchmark_pp,
    avg_forecast_3_month,
    avg_sales_3_month,
    avg_inventory

FROM mart.kpi_backorders_by_forecast_category

ORDER BY
    backorder_rate_pct DESC,
    forecast_category;
