
-- Phase 2, Step 4
-- Action 4.27: Operational Risk Indicators
-- and Historical Backorders

CREATE OR REPLACE VIEW
mart.kpi_backorders_by_risk_indicator AS

WITH indicator_records AS (

    SELECT
        f.sku,
        f.went_on_backorder,
        v.indicator_name,
        v.indicator_value

    FROM mart.fact_inventory f

    CROSS JOIN LATERAL (
        VALUES
            ('potential_issue', f.potential_issue),
            ('deck_risk', f.deck_risk),
            ('oe_constraint', f.oe_constraint),
            ('ppap_risk', f.ppap_risk),
            ('stop_auto_buy', f.stop_auto_buy),
            ('rev_stop', f.rev_stop)
    ) AS v(indicator_name, indicator_value)

    WHERE f.dataset_source = 'train'
      AND f.went_on_backorder IS NOT NULL
),

indicator_groups AS (

    SELECT
        indicator_name,
        CASE
            WHEN indicator_value = TRUE
                THEN 'Active'

            WHEN indicator_value = FALSE
                THEN 'Inactive'

            ELSE 'Unknown'
        END AS indicator_status,

        went_on_backorder

    FROM indicator_records
)

SELECT
    indicator_name,
    indicator_status,

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
    ) AS backorder_rate_pct

FROM indicator_groups

GROUP BY
    indicator_name,
    indicator_status;


-- Action 4.27: Verify Operational Risk KPI View

SELECT
    indicator_name,

    COUNT(*) AS total_status_groups,

    SUM(total_skus) AS total_training_skus,

    SUM(backorder_skus) AS total_backorders,

    SUM(non_backorder_skus) AS total_non_backorders,

    ROUND(
        100.0 * SUM(backorder_skus)
        / NULLIF(SUM(total_skus), 0),
        2
    ) AS overall_backorder_rate_pct

FROM mart.kpi_backorders_by_risk_indicator

GROUP BY indicator_name

ORDER BY indicator_name;


-- Compare backorder rates by operational indicator

SELECT
    indicator_name,
    indicator_status,
    total_skus,
    backorder_skus,
    non_backorder_skus,
    backorder_rate_pct

FROM mart.kpi_backorders_by_risk_indicator

ORDER BY
    indicator_name,
    CASE indicator_status
        WHEN 'Active' THEN 1
        WHEN 'Inactive' THEN 2
        WHEN 'Unknown' THEN 3
        ELSE 4
    END;
