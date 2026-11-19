
-- Phase 2, Step 4
-- Action 4.24: Inventory Demand Coverage KPIs

CREATE OR REPLACE VIEW
mart.kpi_inventory_demand_coverage AS

SELECT
    dataset_source,

    COUNT(*) AS total_skus,

    -- SKUs with positive forecast demand
    COUNT(*) FILTER (
        WHERE forecast_3_month > 0
    ) AS positive_forecast_skus,

    -- Inventory below 3-month forecast demand
    COUNT(*) FILTER (
        WHERE below_3m_forecast_flag = 1
    ) AS below_forecast_skus,

    -- Inventory below historical 3-month sales
    COUNT(*) FILTER (
        WHERE below_3m_sales_flag = 1
    ) AS below_historical_sales_skus,

    -- Missing comparison information
    COUNT(*) FILTER (
        WHERE below_3m_forecast_flag IS NULL
    ) AS unknown_forecast_comparison_skus,

    -- Negative recorded inventory
    COUNT(*) FILTER (
        WHERE national_inv < 0
    ) AS negative_inventory_skus,

    -- Coverage categories
    COUNT(*) FILTER (
        WHERE estimated_stock_cover_months >= 0
          AND estimated_stock_cover_months < 1
    ) AS low_coverage_skus,

    COUNT(*) FILTER (
        WHERE estimated_stock_cover_months >= 1
          AND estimated_stock_cover_months < 3
    ) AS moderate_coverage_skus,

    COUNT(*) FILTER (
        WHERE estimated_stock_cover_months >= 3
    ) AS high_coverage_skus,

    COUNT(*) FILTER (
        WHERE estimated_stock_cover_months IS NULL
    ) AS uncalculated_coverage_skus,

    -- Average estimated coverage
    ROUND(
        AVG(estimated_stock_cover_months)
        FILTER (
            WHERE estimated_stock_cover_months >= 0
        ),
        2
    ) AS avg_nonnegative_stock_cover_months,

    -- Share of records below forecast demand
    ROUND(
        100.0 * COUNT(*) FILTER (
            WHERE below_3m_forecast_flag = 1
        ) / NULLIF(
            COUNT(*) FILTER (
                WHERE below_3m_forecast_flag IS NOT NULL
            ), 0
        ),
        2
    ) AS below_forecast_rate_pct

FROM mart.inventory_demand_forecast

GROUP BY dataset_source;


-- Action 4.24: Verify Inventory Demand Coverage KPIs

SELECT
    dataset_source,

    total_skus,
    positive_forecast_skus,

    below_forecast_skus,
    below_historical_sales_skus,

    negative_inventory_skus,

    low_coverage_skus,
    moderate_coverage_skus,
    high_coverage_skus,

    uncalculated_coverage_skus,

    below_forecast_rate_pct

FROM mart.kpi_inventory_demand_coverage

ORDER BY dataset_source;


-- Verify coverage category reconciliation

SELECT
    dataset_source,

    total_skus,

    (
        low_coverage_skus
        + moderate_coverage_skus
        + high_coverage_skus
        + negative_inventory_skus
        + uncalculated_coverage_skus
    ) AS reconciled_skus,

    total_skus
    - (
        low_coverage_skus
        + moderate_coverage_skus
        + high_coverage_skus
        + negative_inventory_skus
        + uncalculated_coverage_skus
    ) AS difference

FROM mart.kpi_inventory_demand_coverage

ORDER BY dataset_source;
