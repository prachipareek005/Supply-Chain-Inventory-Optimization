
-- Phase 2, Step 4
-- Action 4.29: Backorder Prediction Feature Preparation

CREATE OR REPLACE VIEW mart.backorder_model_features AS

SELECT
    -- Record identification
    sku,
    dataset_source,

    -- Current inventory
    national_inv,
    in_transit_qty,
    min_bank,
    pieces_past_due,
    local_bo_qty,

    -- Demand forecasts
    forecast_3_month,
    forecast_6_month,
    forecast_9_month,

    -- Historical sales
    sales_1_month,
    sales_3_month,
    sales_6_month,
    sales_9_month,

    -- Supply conditions
    lead_time,
    perf_6_month_avg,
    perf_12_month_avg,

    -- Operational risk indicators
    potential_issue,
    deck_risk,
    oe_constraint,
    ppap_risk,
    stop_auto_buy,
    rev_stop,

    -- Feature 1: Nonpositive stock
    CASE
        WHEN national_inv IS NULL THEN NULL
        WHEN national_inv <= 0 THEN 1
        ELSE 0
    END AS feature_nonpositive_stock,

    -- Feature 2: Below minimum stock
    CASE
        WHEN national_inv IS NULL
          OR min_bank IS NULL THEN NULL

        WHEN national_inv < min_bank THEN 1

        ELSE 0
    END AS feature_below_minimum_stock,

    -- Feature 3: Available stock plus in-transit
    CASE
        WHEN national_inv IS NOT NULL
         AND in_transit_qty IS NOT NULL
        THEN national_inv + in_transit_qty
        ELSE NULL
    END AS feature_stock_plus_in_transit,

    -- Feature 4: Forecast demand minus on-hand stock
    CASE
        WHEN national_inv IS NOT NULL
         AND forecast_3_month IS NOT NULL
        THEN forecast_3_month - national_inv
        ELSE NULL
    END AS feature_forecast_inventory_gap,

    -- Feature 5: Inventory relative to demand
    CASE
        WHEN national_inv IS NOT NULL
         AND forecast_3_month > 0
        THEN ROUND(
            national_inv::NUMERIC
            / forecast_3_month::NUMERIC,
            4
        )
        ELSE NULL
    END AS feature_inventory_forecast_ratio,

    -- Feature 6: Forecast versus historical sales
    CASE
        WHEN forecast_3_month IS NOT NULL
         AND sales_3_month > 0
        THEN ROUND(
            forecast_3_month::NUMERIC
            / sales_3_month::NUMERIC,
            4
        )
        ELSE NULL
    END AS feature_forecast_sales_ratio,

    -- Feature 7: Inventory relative to minimum bank
    CASE
        WHEN national_inv IS NOT NULL
         AND min_bank > 0
        THEN ROUND(
            national_inv::NUMERIC
            / min_bank::NUMERIC,
            4
        )
        ELSE NULL
    END AS feature_inventory_minimum_ratio,

    -- Feature 8: Missing lead time
    CASE
        WHEN lead_time IS NULL THEN 1
        ELSE 0
    END AS feature_missing_lead_time,

    -- Feature 9: Unknown supplier performance
    CASE
        WHEN perf_6_month_avg IS NULL THEN 1
        ELSE 0
    END AS feature_missing_supplier_performance,

    -- Target: outcome, NOT an input feature
    CASE
        WHEN dataset_source = 'train'
        THEN went_on_backorder
        ELSE NULL
    END AS target_went_on_backorder

FROM mart.fact_inventory;


-- Action 4.29: Verify Backorder Model Features

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
        WHERE dataset_source = 'train'
          AND target_went_on_backorder = TRUE
    ) AS training_backorders,

    COUNT(*) FILTER (
        WHERE dataset_source = 'train'
          AND target_went_on_backorder = FALSE
    ) AS training_non_backorders,

    COUNT(*) FILTER (
        WHERE dataset_source = 'train'
          AND target_went_on_backorder IS NULL
    ) AS missing_training_targets,

    COUNT(*) FILTER (
        WHERE dataset_source = 'test'
          AND target_went_on_backorder IS NOT NULL
    ) AS incorrectly_labeled_test_records

FROM mart.backorder_model_features;


-- Preview engineered backorder features

SELECT
    sku,
    dataset_source,
    national_inv,
    forecast_3_month,

    feature_nonpositive_stock,
    feature_below_minimum_stock,
    feature_stock_plus_in_transit,
    feature_forecast_inventory_gap,
    feature_inventory_forecast_ratio,
    feature_forecast_sales_ratio,
    feature_missing_lead_time,

    target_went_on_backorder

FROM mart.backorder_model_features

ORDER BY dataset_source, sku

LIMIT 20;
