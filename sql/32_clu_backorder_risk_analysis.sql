
-- Phase 2, Step 4
-- Action 4.19: Historical Backorders by Shortage Risk

CREATE OR REPLACE VIEW mart.kpi_backorders_by_shortage_risk AS

SELECT
    shortage_risk_category,

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

    ROUND(
        AVG(national_inv), 2
    ) AS avg_inventory,

    ROUND(
        AVG(forecast_3_month), 2
    ) AS avg_forecast_3_month,

    ROUND(
        AVG(lead_time) FILTER (
            WHERE lead_time > 0
        ),
        2
    ) AS avg_positive_lead_time

FROM mart.inventory_shortage_risk

WHERE dataset_source = 'train'
  AND went_on_backorder IS NOT NULL

GROUP BY shortage_risk_category;


-- Action 4.19: Verify Historical Backorder Analysis

SELECT
    COUNT(*) AS total_risk_categories,

    SUM(total_skus) AS total_training_skus,

    SUM(backorder_skus) AS total_backorders,

    SUM(non_backorder_skus)
        AS total_non_backorders,

    ROUND(
        100.0 * SUM(backorder_skus)
        / NULLIF(SUM(total_skus), 0),
        2
    ) AS overall_backorder_rate_pct

FROM mart.kpi_backorders_by_shortage_risk;


-- Preview backorder rates by shortage-risk category

SELECT
    shortage_risk_category,
    total_skus,
    backorder_skus,
    non_backorder_skus,
    backorder_rate_pct,
    avg_inventory,
    avg_forecast_3_month,
    avg_positive_lead_time

FROM mart.kpi_backorders_by_shortage_risk

ORDER BY
    CASE shortage_risk_category
        WHEN 'High' THEN 1
        WHEN 'Moderate' THEN 2
        WHEN 'Low' THEN 3
        WHEN 'Unknown' THEN 4
        ELSE 5
    END;
