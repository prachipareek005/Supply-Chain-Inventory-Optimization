
-- Phase 2, Step 4
-- Action 4.32: Final CLU Analytics Reconciliation

WITH checks AS (

    -- 1. Inventory fact: total records
    SELECT
        '01 - Inventory fact rows' AS check_name,
        (SELECT COUNT(*)::NUMERIC
         FROM mart.fact_inventory) AS actual_value,
        19053::NUMERIC AS expected_value

    UNION ALL
    -- 2. Inventory fact: unique SKUs
    SELECT
        '02 - Unique inventory SKUs',
        (SELECT COUNT(DISTINCT sku)::NUMERIC
         FROM mart.fact_inventory),
        19053::NUMERIC

    UNION ALL
    -- 3. Training population
    SELECT
        '03 - Training SKUs',
        (SELECT COUNT(*)::NUMERIC
         FROM mart.fact_inventory
         WHERE dataset_source = 'train'),
        15243::NUMERIC

    UNION ALL
    -- 4. Test population
    SELECT
        '04 - Test SKUs',
        (SELECT COUNT(*)::NUMERIC
         FROM mart.fact_inventory
         WHERE dataset_source = 'test'),
        3810::NUMERIC

    UNION ALL
    -- 5. Training backorders
    SELECT
        '05 - Training backorders',
        (SELECT COUNT(*)::NUMERIC
         FROM mart.fact_inventory
         WHERE dataset_source = 'train'
           AND went_on_backorder = TRUE),
        1813::NUMERIC

    UNION ALL
    -- 6. Training non-backorders
    SELECT
        '06 - Training non-backorders',
        (SELECT COUNT(*)::NUMERIC
         FROM mart.fact_inventory
         WHERE dataset_source = 'train'
           AND went_on_backorder = FALSE),
        13430::NUMERIC

    UNION ALL
    -- 7. Missing training labels
    SELECT
        '07 - Missing training labels',
        (SELECT COUNT(*)::NUMERIC
         FROM mart.fact_inventory
         WHERE dataset_source = 'train'
           AND went_on_backorder IS NULL),
        0::NUMERIC

    UNION ALL
    -- 8. Incorrectly labeled test SKUs
    SELECT
        '08 - Labeled test SKUs',
        (SELECT COUNT(*)::NUMERIC
         FROM mart.fact_inventory
         WHERE dataset_source = 'test'
           AND went_on_backorder IS NOT NULL),
        0::NUMERIC

    UNION ALL
    -- 9. Inventory availability total
    SELECT
        '09 - Inventory availability total',
        (SELECT SUM(total_skus)::NUMERIC
         FROM mart.kpi_inventory_availability),
        19053::NUMERIC

    UNION ALL
    -- 10. Training negative inventory
    SELECT
        '10 - Training negative inventory',
        (SELECT SUM(negative_stock_skus)::NUMERIC
         FROM mart.kpi_inventory_availability
         WHERE dataset_source = 'train'),
        170::NUMERIC

    UNION ALL
    -- 11. Test negative inventory
    SELECT
        '11 - Test negative inventory',
        (SELECT SUM(negative_stock_skus)::NUMERIC
         FROM mart.kpi_inventory_availability
         WHERE dataset_source = 'test'),
        48::NUMERIC

    UNION ALL
    -- 12. Shortage risk total
    SELECT
        '12 - Shortage risk rows',
        (SELECT COUNT(*)::NUMERIC
         FROM mart.inventory_shortage_risk),
        19053::NUMERIC

    UNION ALL
    -- 13. Demand forecast rows
    SELECT
        '13 - Demand forecast rows',
        (SELECT COUNT(*)::NUMERIC
         FROM mart.inventory_demand_forecast),
        19053::NUMERIC

    UNION ALL
    -- 14. Demand coverage total
    SELECT
        '14 - Demand coverage total',
        (SELECT SUM(total_skus)::NUMERIC
         FROM mart.kpi_inventory_demand_coverage),
        19053::NUMERIC

    UNION ALL
    -- 15. Forecast comparison total
    SELECT
        '15 - Forecast vs sales total',
        (SELECT SUM(total_skus)::NUMERIC
         FROM mart.kpi_forecast_vs_sales),
        19053::NUMERIC

    UNION ALL
    -- 16. Shortage risk backorders
    SELECT
        '16 - Shortage risk backorders',
        (SELECT SUM(backorder_skus)::NUMERIC
         FROM mart.kpi_backorders_by_shortage_risk),
        1813::NUMERIC

    UNION ALL
    -- 17. Lead-time backorders
    SELECT
        '17 - Lead-time backorders',
        (SELECT SUM(backorder_skus)::NUMERIC
         FROM mart.kpi_backorders_by_lead_time),
        1813::NUMERIC

    UNION ALL
    -- 18. Forecast category backorders
    SELECT
        '18 - Forecast category backorders',
        (SELECT SUM(backorder_skus)::NUMERIC
         FROM mart.kpi_backorders_by_forecast_category),
        1813::NUMERIC

    UNION ALL
    -- 19. Model feature rows
    SELECT
        '19 - Model feature rows',
        (SELECT COUNT(*)::NUMERIC
         FROM mart.backorder_model_features),
        19053::NUMERIC

    UNION ALL
    -- 20. Model feature backorders
    SELECT
        '20 - Model feature backorders',
        (SELECT COUNT(*)::NUMERIC
         FROM mart.backorder_model_features
         WHERE dataset_source = 'train'
           AND target_went_on_backorder = TRUE),
        1813::NUMERIC

    UNION ALL
    -- 21. Feature quality groups
    SELECT
        '21 - Feature quality groups',
        (SELECT COUNT(*)::NUMERIC
         FROM mart.kpi_backorder_feature_quality),
        40::NUMERIC

    UNION ALL
    -- 22. Readiness groups
    SELECT
        '22 - Modeling readiness groups',
        (SELECT COUNT(*)::NUMERIC
         FROM mart.kpi_backorder_model_readiness),
        2::NUMERIC

    UNION ALL
    -- 23. Training readiness population
    SELECT
        '23 - Training readiness SKUs',
        (SELECT total_skus::NUMERIC
         FROM mart.kpi_backorder_model_readiness
         WHERE dataset_source = 'train'),
        15243::NUMERIC

    UNION ALL
    -- 24. Test readiness population
    SELECT
        '24 - Test readiness SKUs',
        (SELECT total_skus::NUMERIC
         FROM mart.kpi_backorder_model_readiness
         WHERE dataset_source = 'test'),
        3810::NUMERIC
)

SELECT
    check_name,
    actual_value,
    expected_value,
    actual_value - expected_value AS difference,

    CASE
        WHEN actual_value = expected_value
            THEN 'PASS'
        ELSE 'FAIL'
    END AS verification_status

FROM checks

ORDER BY check_name;


-- Final CLU population and target summary

SELECT
    COUNT(*) AS total_skus,

    COUNT(DISTINCT sku) AS unique_skus,

    COUNT(*) FILTER (
        WHERE dataset_source = 'train'
    ) AS training_skus,

    COUNT(*) FILTER (
        WHERE dataset_source = 'test'
    ) AS test_skus,

    COUNT(*) FILTER (
        WHERE dataset_source = 'train'
          AND went_on_backorder = TRUE
    ) AS confirmed_backorders,

    COUNT(*) FILTER (
        WHERE dataset_source = 'train'
          AND went_on_backorder = FALSE
    ) AS confirmed_non_backorders

FROM mart.fact_inventory;
