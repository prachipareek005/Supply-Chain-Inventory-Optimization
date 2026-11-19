
-- Phase 2, Step 4
-- Action 4.31: Backorder Modeling Readiness Assessment

CREATE OR REPLACE VIEW
mart.kpi_backorder_model_readiness AS

WITH target_summary AS (

    SELECT
        dataset_source,

        COUNT(*) AS total_skus,

        COUNT(DISTINCT sku) AS unique_skus,

        COUNT(*) FILTER (
            WHERE target_went_on_backorder = TRUE
        ) AS backorder_skus,

        COUNT(*) FILTER (
            WHERE target_went_on_backorder = FALSE
        ) AS non_backorder_skus,

        COUNT(*) FILTER (
            WHERE target_went_on_backorder IS NULL
        ) AS unlabeled_skus

    FROM mart.backorder_model_features

    GROUP BY dataset_source
),

feature_summary AS (

    SELECT
        dataset_source,

        COUNT(*) AS assessed_features,

        COUNT(*) FILTER (
            WHERE missing_values = 0
        ) AS complete_features,

        COUNT(*) FILTER (
            WHERE missing_rate_pct > 20
        ) AS high_missingness_features,

        COUNT(*) FILTER (
            WHERE distinct_nonnull_values <= 1
        ) AS low_variation_features,

        MAX(missing_rate_pct)
            AS highest_missing_rate_pct,

        COUNT(*) FILTER (
            WHERE available_values + missing_values
                  <> total_skus
        ) AS feature_reconciliation_failures

    FROM mart.kpi_backorder_feature_quality

    GROUP BY dataset_source
)

SELECT
    t.dataset_source,

    t.total_skus,
    t.unique_skus,

    t.backorder_skus,
    t.non_backorder_skus,
    t.unlabeled_skus,

    -- Historical target distribution
    CASE
        WHEN t.dataset_source = 'train'
        THEN ROUND(
            100.0 * t.backorder_skus
            / NULLIF(t.total_skus, 0),
            2
        )
        ELSE NULL
    END AS backorder_rate_pct,

    -- Majority-to-minority class ratio
    CASE
        WHEN t.dataset_source = 'train'
        THEN ROUND(
            t.non_backorder_skus::NUMERIC
            / NULLIF(t.backorder_skus, 0),
            2
        )
        ELSE NULL
    END AS non_backorder_to_backorder_ratio,

    f.assessed_features,
    f.complete_features,
    f.high_missingness_features,
    f.low_variation_features,
    f.highest_missing_rate_pct,
    f.feature_reconciliation_failures,

    -- Preliminary structural readiness only
    CASE
        WHEN t.total_skus <> t.unique_skus
            THEN 'Review Duplicate SKUs'

        WHEN f.assessed_features <> 20
          OR f.feature_reconciliation_failures > 0
            THEN 'Review Feature Quality'

        WHEN t.dataset_source = 'train'
         AND t.unlabeled_skus > 0
            THEN 'Review Training Labels'

        WHEN t.dataset_source = 'test'
         AND (
             t.backorder_skus > 0
             OR t.non_backorder_skus > 0
         )
            THEN 'Review Test Labels'

        ELSE 'Structural Checks Passed'
    END AS structural_readiness_status

FROM target_summary t

JOIN feature_summary f
    ON t.dataset_source = f.dataset_source;


-- Action 4.31: Verify Backorder Model Readiness

SELECT
    dataset_source,

    total_skus,
    unique_skus,

    backorder_skus,
    non_backorder_skus,
    unlabeled_skus,

    backorder_rate_pct,
    non_backorder_to_backorder_ratio,

    assessed_features,
    high_missingness_features,
    low_variation_features,

    feature_reconciliation_failures,
    structural_readiness_status

FROM mart.kpi_backorder_model_readiness

ORDER BY dataset_source;


-- Action 4.31: Features requiring further review

SELECT
    dataset_source,
    feature_name,
    missing_rate_pct,
    distinct_nonnull_values,

    CASE
        WHEN distinct_nonnull_values <= 1
            THEN 'Low Variation'

        WHEN missing_rate_pct > 20
            THEN 'High Missingness'

        WHEN missing_rate_pct > 0
            THEN 'Missing Values Present'

        ELSE 'No Issue Detected by These Checks'
    END AS review_reason

FROM mart.kpi_backorder_feature_quality

WHERE missing_rate_pct > 0
   OR distinct_nonnull_values <= 1

ORDER BY
    dataset_source,
    missing_rate_pct DESC,
    feature_name;
