
-- Phase 2, Step 4
-- Action 4.16: Create CLU Inventory Analytics View

CREATE OR REPLACE VIEW mart.fact_inventory AS

SELECT
    sku,
    'train'::TEXT AS dataset_source,

    national_inv,
    lead_time,
    in_transit_qty,

    forecast_3_month,
    forecast_6_month,
    forecast_9_month,

    sales_1_month,
    sales_3_month,
    sales_6_month,
    sales_9_month,

    min_bank,
    pieces_past_due,
    local_bo_qty,

    perf_6_month_avg,
    perf_12_month_avg,

    potential_issue,
    deck_risk,
    oe_constraint,
    ppap_risk,
    stop_auto_buy,
    rev_stop,

    went_on_backorder,

    negative_inventory_flag,
    missing_lead_time_flag,
    zero_lead_time_flag,
    perf_6m_sentinel_flag,
    perf_12m_sentinel_flag

FROM clean.clu_train

UNION ALL

SELECT
    sku,
    'test'::TEXT AS dataset_source,

    national_inv,
    lead_time,
    in_transit_qty,

    forecast_3_month,
    forecast_6_month,
    forecast_9_month,

    sales_1_month,
    sales_3_month,
    sales_6_month,
    sales_9_month,

    min_bank,
    pieces_past_due,
    local_bo_qty,

    perf_6_month_avg,
    perf_12_month_avg,

    potential_issue,
    deck_risk,
    oe_constraint,
    ppap_risk,
    stop_auto_buy,
    rev_stop,

    NULL::BOOLEAN AS went_on_backorder,

    negative_inventory_flag,
    missing_lead_time_flag,
    zero_lead_time_flag,
    perf_6m_sentinel_flag,
    perf_12m_sentinel_flag

FROM clean.clu_test;


-- Action 4.16: Verify CLU Inventory Analytics View

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
          AND went_on_backorder IS NULL
    ) AS missing_training_labels,

    COUNT(*) FILTER (
        WHERE dataset_source = 'test'
          AND went_on_backorder IS NOT NULL
    ) AS incorrectly_labeled_test_records,

    COUNT(*) FILTER (
        WHERE dataset_source = 'train'
          AND went_on_backorder = TRUE
    ) AS confirmed_backorders

FROM mart.fact_inventory;
