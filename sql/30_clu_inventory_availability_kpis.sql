
-- Phase 2, Step 4
-- Action 4.17: Inventory Availability & Shortage KPIs

CREATE OR REPLACE VIEW mart.kpi_inventory_availability AS

SELECT
    dataset_source,

    COUNT(*) AS total_skus,

    -- Current recorded inventory
    COUNT(*) FILTER (
        WHERE national_inv > 0
    ) AS positive_stock_skus,

    COUNT(*) FILTER (
        WHERE national_inv = 0
    ) AS zero_stock_skus,

    COUNT(*) FILTER (
        WHERE national_inv < 0
    ) AS negative_stock_skus,

    COUNT(*) FILTER (
        WHERE national_inv <= 0
    ) AS nonpositive_stock_skus,

    -- Stock below recorded minimum bank
    COUNT(*) FILTER (
        WHERE national_inv < min_bank
    ) AS below_minimum_stock_skus,

    -- Percentage with nonpositive stock
    ROUND(
        100.0 * COUNT(*) FILTER (
            WHERE national_inv <= 0
        ) / NULLIF(
            COUNT(*) FILTER (
                WHERE national_inv IS NOT NULL
            ), 0
        ),
        2
    ) AS nonpositive_stock_rate_pct,

    -- Inventory quantities
    SUM(national_inv) AS total_recorded_inventory,

    SUM(in_transit_qty) AS total_in_transit_qty,

    -- Supplier lead-time quality
    COALESCE(
        SUM(missing_lead_time_flag), 0
    ) AS missing_lead_time_skus,

    COALESCE(
        SUM(zero_lead_time_flag), 0
    ) AS zero_lead_time_skus,

    ROUND(
        AVG(lead_time) FILTER (
            WHERE lead_time > 0
        ),
        2
    ) AS avg_positive_lead_time,

    -- Known historical backorders (training only)
    COUNT(*) FILTER (
        WHERE dataset_source = 'train'
          AND went_on_backorder = TRUE
    ) AS confirmed_backorder_skus

FROM mart.fact_inventory

GROUP BY dataset_source;


-- Action 4.17: Verify Inventory Availability KPIs

SELECT
    dataset_source,
    total_skus,
    positive_stock_skus,
    zero_stock_skus,
    negative_stock_skus,
    nonpositive_stock_skus,
    below_minimum_stock_skus,
    missing_lead_time_skus,
    zero_lead_time_skus,
    confirmed_backorder_skus

FROM mart.kpi_inventory_availability

ORDER BY dataset_source;
