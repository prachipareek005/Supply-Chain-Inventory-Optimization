
-- Phase 2, Step 4
-- Action 4.28: Operational Risk Flag Effectiveness

CREATE OR REPLACE VIEW
mart.kpi_risk_indicator_effectiveness AS

WITH indicator_summary AS (
    SELECT
        indicator_name,

        SUM(total_skus) FILTER (
            WHERE indicator_status = 'Active'
        ) AS active_skus,

        SUM(total_skus) FILTER (
            WHERE indicator_status = 'Inactive'
        ) AS inactive_skus,

        SUM(total_skus) FILTER (
            WHERE indicator_status = 'Unknown'
        ) AS unknown_skus,

        SUM(backorder_skus) FILTER (
            WHERE indicator_status = 'Active'
        ) AS active_backorders,

        SUM(backorder_skus) FILTER (
            WHERE indicator_status = 'Inactive'
        ) AS inactive_backorders,

        SUM(backorder_skus) FILTER (
            WHERE indicator_status = 'Unknown'
        ) AS unknown_backorders

    FROM mart.kpi_backorders_by_risk_indicator

    GROUP BY indicator_name
),

rates AS (
    SELECT
        indicator_name,

        COALESCE(active_skus, 0) AS active_skus,
        COALESCE(inactive_skus, 0) AS inactive_skus,
        COALESCE(unknown_skus, 0) AS unknown_skus,

        COALESCE(active_backorders, 0)
            AS active_backorders,

        COALESCE(inactive_backorders, 0)
            AS inactive_backorders,

        COALESCE(unknown_backorders, 0)
            AS unknown_backorders,

        100.0 * active_backorders
            / NULLIF(active_skus, 0)
            AS active_rate_raw,

        100.0 * inactive_backorders
            / NULLIF(inactive_skus, 0)
            AS inactive_rate_raw

    FROM indicator_summary
)

SELECT
    indicator_name,

    active_skus,
    inactive_skus,
    unknown_skus,

    active_backorders,
    inactive_backorders,
    unknown_backorders,

    ROUND(active_rate_raw, 2)
        AS active_backorder_rate_pct,

    ROUND(inactive_rate_raw, 2)
        AS inactive_backorder_rate_pct,

    ROUND(
        active_rate_raw - inactive_rate_raw,
        2
    ) AS rate_difference_pp,

    ROUND(
        active_rate_raw
        / NULLIF(inactive_rate_raw, 0),
        2
    ) AS relative_backorder_rate,

    ROUND(
        100.0 * active_backorders
        / NULLIF(
            active_backorders
            + inactive_backorders
            + unknown_backorders,
            0
        ),
        2
    ) AS backorder_capture_pct,

    CASE
        WHEN active_skus < 30
          OR inactive_skus < 30
            THEN 'Insufficient Sample'

        WHEN active_rate_raw > inactive_rate_raw
            THEN 'Higher When Active'

        WHEN active_rate_raw < inactive_rate_raw
            THEN 'Lower When Active'

        ELSE 'Similar or Unavailable'
    END AS observed_association

FROM rates;


-- Action 4.28: Verify Risk Indicator Effectiveness

SELECT
    COUNT(*) AS total_indicators,

    COUNT(*) FILTER (
        WHERE active_skus
            + inactive_skus
            + unknown_skus = 15243
    ) AS indicators_with_correct_sku_totals,

    COUNT(*) FILTER (
        WHERE active_backorders
            + inactive_backorders
            + unknown_backorders = 1813
    ) AS indicators_with_correct_backorder_totals,

    COUNT(*) FILTER (
        WHERE observed_association IS NULL
    ) AS unclassified_indicators

FROM mart.kpi_risk_indicator_effectiveness;


-- Preview operational risk indicator effectiveness

SELECT
    indicator_name,
    active_skus,
    inactive_skus,
    active_backorders,
    active_backorder_rate_pct,
    inactive_backorder_rate_pct,
    rate_difference_pp,
    relative_backorder_rate,
    backorder_capture_pct,
    observed_association

FROM mart.kpi_risk_indicator_effectiveness

ORDER BY
    rate_difference_pp DESC NULLS LAST,
    indicator_name;
