
-- Phase 2, Step 4
-- Action 4.18: Inventory Shortage Risk Indicators

CREATE OR REPLACE VIEW mart.inventory_shortage_risk AS

WITH inventory_metrics AS (
    SELECT
        sku,
        dataset_source,

        national_inv,
        in_transit_qty,
        min_bank,

        forecast_3_month,
        sales_3_month,

        lead_time,
        went_on_backorder,

        -- On-hand inventory plus in-transit inventory
        CASE
            WHEN national_inv IS NOT NULL
             AND in_transit_qty IS NOT NULL
            THEN national_inv + in_transit_qty
            ELSE NULL
        END AS stock_plus_in_transit,

        -- Nonpositive inventory flag
        CASE
            WHEN national_inv <= 0 THEN 1
            ELSE 0
        END AS nonpositive_stock_flag,

        -- Inventory below recorded minimum bank
        CASE
            WHEN national_inv < min_bank THEN 1
            ELSE 0
        END AS below_minimum_stock_flag

    FROM mart.fact_inventory
),

risk_metrics AS (
    SELECT
        *,

        -- Simplified 3-month forecast coverage
        CASE
            WHEN stock_plus_in_transit IS NOT NULL
             AND forecast_3_month > 0
            THEN ROUND(
                stock_plus_in_transit
                / forecast_3_month,
                3
            )
            ELSE NULL
        END AS forecast_3m_coverage_ratio,

        CASE
            WHEN stock_plus_in_transit IS NOT NULL
             AND forecast_3_month > 0
             AND stock_plus_in_transit < forecast_3_month
            THEN 1 ELSE 0
        END AS forecast_3m_shortage_flag

    FROM inventory_metrics
)

SELECT
    *,

    CASE
        WHEN nonpositive_stock_flag = 1
            THEN 'High'

        WHEN below_minimum_stock_flag = 1
          OR forecast_3m_shortage_flag = 1
            THEN 'Moderate'

        WHEN national_inv IS NULL
          OR min_bank IS NULL
          OR stock_plus_in_transit IS NULL
            THEN 'Unknown'

        ELSE 'Low'
    END AS shortage_risk_category

FROM risk_metrics;


-- Action 4.18: Verify inventory shortage-risk view

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
        WHERE shortage_risk_category = 'High'
    ) AS high_risk_skus,

    COUNT(*) FILTER (
        WHERE shortage_risk_category = 'Moderate'
    ) AS moderate_risk_skus,

    COUNT(*) FILTER (
        WHERE shortage_risk_category = 'Low'
    ) AS low_risk_skus,

    COUNT(*) FILTER (
        WHERE shortage_risk_category = 'Unknown'
    ) AS unknown_risk_skus

FROM mart.inventory_shortage_risk;
