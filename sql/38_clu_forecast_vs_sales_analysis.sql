
-- Phase 2, Step 4
-- Action 4.25: Forecast Demand vs Historical Sales

CREATE OR REPLACE VIEW mart.kpi_forecast_vs_sales AS

WITH forecast_comparison AS (
    SELECT
        sku,
        dataset_source,
        forecast_3_month,
        sales_3_month,
        national_inv,

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
)

SELECT
    dataset_source,
    forecast_category,

    COUNT(*) AS total_skus,

    ROUND(
        AVG(forecast_3_month), 2
    ) AS avg_forecast_3_month,

    ROUND(
        AVG(sales_3_month), 2
    ) AS avg_sales_3_month,

    ROUND(
        AVG(national_inv), 2
    ) AS avg_inventory,

    COUNT(*) FILTER (
        WHERE national_inv < forecast_3_month
    ) AS below_forecast_inventory_skus,

    ROUND(
        100.0 * COUNT(*)
        / NULLIF(
            SUM(COUNT(*)) OVER (
                PARTITION BY dataset_source
            ), 0
        ),
        2
    ) AS category_share_pct

FROM forecast_comparison

GROUP BY
    dataset_source,
    forecast_category;


-- Action 4.25: Forecast vs Sales Verification

SELECT
    dataset_source,

    COUNT(*) AS total_categories,

    SUM(total_skus) AS total_skus,

    SUM(below_forecast_inventory_skus)
        AS below_forecast_skus,

    ROUND(
        SUM(category_share_pct), 2
    ) AS total_category_share_pct,

    COUNT(*) FILTER (
        WHERE forecast_category IS NULL
    ) AS unclassified_categories

FROM mart.kpi_forecast_vs_sales

GROUP BY dataset_source

ORDER BY dataset_source;


-- Preview forecast demand categories

SELECT
    dataset_source,
    forecast_category,
    total_skus,
    category_share_pct,
    avg_forecast_3_month,
    avg_sales_3_month,
    avg_inventory,
    below_forecast_inventory_skus

FROM mart.kpi_forecast_vs_sales

ORDER BY
    dataset_source,
    total_skus DESC;
