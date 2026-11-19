
-- Phase 2, Step 4
-- Action 4.30: Backorder Feature Quality Assessment

CREATE OR REPLACE VIEW
mart.kpi_backorder_feature_quality AS

WITH feature_records AS (

    SELECT
        f.dataset_source,
        f.sku,
        v.feature_name,
        v.feature_value

    FROM mart.backorder_model_features f

    CROSS JOIN LATERAL (
        VALUES

        -- Original inventory features
        ('national_inv',
            f.national_inv::TEXT),

        ('in_transit_qty',
            f.in_transit_qty::TEXT),

        ('min_bank',
            f.min_bank::TEXT),

        ('pieces_past_due',
            f.pieces_past_due::TEXT),

        ('local_bo_qty',
            f.local_bo_qty::TEXT),

        -- Demand and sales
        ('forecast_3_month',
            f.forecast_3_month::TEXT),

        ('forecast_6_month',
            f.forecast_6_month::TEXT),

        ('forecast_9_month',
            f.forecast_9_month::TEXT),

        ('sales_3_month',
            f.sales_3_month::TEXT),

        -- Supplier features
        ('lead_time',
            f.lead_time::TEXT),

        ('perf_6_month_avg',
            f.perf_6_month_avg::TEXT),

        ('perf_12_month_avg',
            f.perf_12_month_avg::TEXT),

        -- Engineered features
        ('feature_nonpositive_stock',
            f.feature_nonpositive_stock::TEXT),

        ('feature_below_minimum_stock',
            f.feature_below_minimum_stock::TEXT),

        ('feature_stock_plus_in_transit',
            f.feature_stock_plus_in_transit::TEXT),

        ('feature_forecast_inventory_gap',
            f.feature_forecast_inventory_gap::TEXT),

        ('feature_inventory_forecast_ratio',
            f.feature_inventory_forecast_ratio::TEXT),

        ('feature_forecast_sales_ratio',
            f.feature_forecast_sales_ratio::TEXT),

        ('feature_missing_lead_time',
            f.feature_missing_lead_time::TEXT),

        ('feature_missing_supplier_performance',
            f.feature_missing_supplier_performance::TEXT)

    ) AS v(feature_name, feature_value)
)

SELECT
    dataset_source,
    feature_name,

    COUNT(*) AS total_skus,

    COUNT(feature_value) AS available_values,

    COUNT(*) FILTER (
        WHERE feature_value IS NULL
    ) AS missing_values,

    ROUND(
        100.0 * COUNT(*) FILTER (
            WHERE feature_value IS NULL
        ) / NULLIF(COUNT(*), 0),
        2
    ) AS missing_rate_pct,

    COUNT(DISTINCT feature_value)
        AS distinct_nonnull_values,

    CASE
        WHEN COUNT(*) FILTER (
            WHERE feature_value IS NULL
        ) = 0
            THEN 'Complete'

        WHEN 100.0 * COUNT(*) FILTER (
            WHERE feature_value IS NULL
        ) / NULLIF(COUNT(*), 0) <= 5
            THEN 'Low Missingness'

        WHEN 100.0 * COUNT(*) FILTER (
            WHERE feature_value IS NULL
        ) / NULLIF(COUNT(*), 0) <= 20
            THEN 'Moderate Missingness'

        ELSE 'High Missingness'
    END AS feature_quality_status

FROM feature_records

GROUP BY
    dataset_source,
    feature_name;


-- Action 4.30: Verify Feature Quality Assessment

SELECT
    dataset_source,

    COUNT(*) AS total_features,

    COUNT(*) FILTER (
        WHERE feature_quality_status = 'Complete'
    ) AS complete_features,

    COUNT(*) FILTER (
        WHERE feature_quality_status = 'Low Missingness'
    ) AS low_missingness_features,

    COUNT(*) FILTER (
        WHERE feature_quality_status = 'Moderate Missingness'
    ) AS moderate_missingness_features,

    COUNT(*) FILTER (
        WHERE feature_quality_status = 'High Missingness'
    ) AS high_missingness_features,

    COUNT(*) FILTER (
        WHERE available_values + missing_values
              <> total_skus
    ) AS reconciliation_failures,

    MIN(total_skus) AS minimum_sku_count,

    MAX(total_skus) AS maximum_sku_count

FROM mart.kpi_backorder_feature_quality

GROUP BY dataset_source

ORDER BY dataset_source;


-- Preview feature missingness
-- Highest missing rate first

SELECT
    dataset_source,
    feature_name,
    total_skus,
    available_values,
    missing_values,
    missing_rate_pct,
    distinct_nonnull_values,
    feature_quality_status

FROM mart.kpi_backorder_feature_quality

ORDER BY
    dataset_source,
    missing_rate_pct DESC,
    feature_name;
