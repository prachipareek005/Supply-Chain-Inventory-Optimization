
-- Phase 2, Step 4
-- Action 4.23: Inventory Demand & Forecast Analysis

CREATE OR REPLACE VIEW mart.inventory_demand_forecast AS

WITH inventory_base AS (

    SELECT
        sku,
        dataset_source,

        national_inv,
        in_transit_qty,
        min_bank,

        forecast_3_month,
        forecast_6_month,
        forecast_9_month,

        sales_1_month,
        sales_3_month,
        sales_6_month,
        sales_9_month,

        went_on_backorder

    FROM mart.fact_inventory
)

SELECT
    *,

    -- Average monthly historical sales
    ROUND(
        sales_3_month::NUMERIC / 3,
        2
    ) AS avg_monthly_sales_3m,

    -- Average monthly forecast demand
    ROUND(
        forecast_3_month::NUMERIC / 3,
        2
    ) AS avg_monthly_forecast_3m,

    -- Forecast relative to historical sales
    CASE
        WHEN sales_3_month > 0
        THEN ROUND(
            forecast_3_month::NUMERIC
            / sales_3_month::NUMERIC,
            3
        )
        ELSE NULL
    END AS forecast_to_sales_ratio_3m,

    -- Inventory relative to forecast demand
    CASE
        WHEN forecast_3_month > 0
        THEN ROUND(
            national_inv::NUMERIC
            / forecast_3_month::NUMERIC,
            3
        )
        ELSE NULL
    END AS inventory_to_forecast_ratio_3m,

    -- Estimated months of on-hand inventory coverage
    CASE
        WHEN forecast_3_month > 0
        THEN ROUND(
            national_inv::NUMERIC
            / (forecast_3_month::NUMERIC / 3),
            2
        )
        ELSE NULL
    END AS estimated_stock_cover_months,

    -- Inventory below forecasted 3-month demand
    CASE
        WHEN national_inv IS NULL
          OR forecast_3_month IS NULL
        THEN NULL

        WHEN national_inv < forecast_3_month
        THEN 1

        ELSE 0
    END AS below_3m_forecast_flag,

    -- Inventory below historical 3-month sales
    CASE
        WHEN national_inv IS NULL
          OR sales_3_month IS NULL
        THEN NULL

        WHEN national_inv < sales_3_month
        THEN 1

        ELSE 0
    END AS below_3m_sales_flag

FROM inventory_base;


-- Action 4.23: Verify Inventory Demand & Forecast

SELECT
    COUNT(*) AS total_records,

    COUNT(DISTINCT sku) AS unique_skus,

    COUNT(*) FILTER (
        WHERE dataset_source = 'train'
    ) AS training_records,

    COUNT(*) FILTER (
        WHERE dataset_source = 'test'
    ) AS test_records,

    COUNT(*) FILTER (
        WHERE forecast_3_month > 0
    ) AS positive_forecast_skus,

    COUNT(*) FILTER (
        WHERE below_3m_forecast_flag = 1
    ) AS below_forecast_skus,

    COUNT(*) FILTER (
        WHERE below_3m_sales_flag = 1
    ) AS below_historical_sales_skus,

    COUNT(*) FILTER (
        WHERE estimated_stock_cover_months IS NOT NULL
    ) AS calculated_stock_cover_skus,

    COUNT(*) FILTER (
        WHERE below_3m_forecast_flag IS NULL
    ) AS unknown_forecast_comparison_skus

FROM mart.inventory_demand_forecast;


-- Preview SKUs with less than one month of stock cover

SELECT
    sku,
    dataset_source,
    national_inv,
    forecast_3_month,
    sales_3_month,
    inventory_to_forecast_ratio_3m,
    estimated_stock_cover_months,
    below_3m_forecast_flag

FROM mart.inventory_demand_forecast

WHERE estimated_stock_cover_months >= 0
  AND estimated_stock_cover_months < 1

ORDER BY
    estimated_stock_cover_months ASC,
    sku

LIMIT 20;
