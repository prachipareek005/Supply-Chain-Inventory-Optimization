
-- Phase 2, Step 4
-- Action 4.20: Lead-Time and Backorder Analysis

CREATE OR REPLACE VIEW mart.kpi_backorders_by_lead_time AS

WITH lead_time_groups AS (
    SELECT
        sku,
        national_inv,
        lead_time,
        went_on_backorder,

        CASE
            WHEN lead_time IS NULL
                THEN 'Unknown'

            WHEN lead_time = 0
                THEN 'Zero'

            WHEN lead_time > 0 AND lead_time <= 4
                THEN '1-4'

            WHEN lead_time > 4 AND lead_time <= 8
                THEN '5-8'

            WHEN lead_time > 8 AND lead_time <= 12
                THEN '9-12'

            WHEN lead_time > 12
                THEN 'Over 12'

            ELSE 'Invalid Negative'
        END AS lead_time_category

    FROM mart.fact_inventory
    WHERE dataset_source = 'train'
      AND went_on_backorder IS NOT NULL
)

SELECT
    lead_time_category,

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
        AVG(lead_time), 2
    ) AS avg_lead_time,

    ROUND(
        AVG(national_inv), 2
    ) AS avg_inventory

FROM lead_time_groups

GROUP BY lead_time_category;


-- Action 4.20: Verify Lead-Time Backorder Analysis

SELECT
    COUNT(*) AS total_lead_time_groups,

    SUM(total_skus) AS total_training_skus,

    SUM(backorder_skus) AS total_backorders,

    SUM(non_backorder_skus)
        AS total_non_backorders,

    ROUND(
        100.0 * SUM(backorder_skus)
        / NULLIF(SUM(total_skus), 0),
        2
    ) AS overall_backorder_rate_pct,

    COALESCE(
        SUM(total_skus) FILTER (
            WHERE lead_time_category = 'Unknown'
        ), 0
    ) AS missing_lead_time_skus,

    COALESCE(
        SUM(total_skus) FILTER (
            WHERE lead_time_category = 'Zero'
        ), 0
    ) AS zero_lead_time_skus

FROM mart.kpi_backorders_by_lead_time;


-- Preview backorder rates across lead-time groups

SELECT
    lead_time_category,
    total_skus,
    backorder_skus,
    non_backorder_skus,
    backorder_rate_pct,
    avg_lead_time,
    avg_inventory

FROM mart.kpi_backorders_by_lead_time

ORDER BY
    CASE lead_time_category
        WHEN 'Unknown' THEN 1
        WHEN 'Zero' THEN 2
        WHEN '1-4' THEN 3
        WHEN '5-8' THEN 4
        WHEN '9-12' THEN 5
        WHEN 'Over 12' THEN 6
        ELSE 7
    END;
