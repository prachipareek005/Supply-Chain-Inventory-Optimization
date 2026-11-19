-- Phase 5 - Action 5.4.5
-- Create a dedicated table for ML-generated SKU risk predictions

CREATE TABLE IF NOT EXISTS mart.sku_backorder_predictions (

    sku TEXT PRIMARY KEY,

    predicted_backorder_probability NUMERIC(14,10) NOT NULL
        CHECK (
            predicted_backorder_probability >= 0
            AND predicted_backorder_probability <= 1
        ),

    predicted_backorder_flag SMALLINT NOT NULL
        CHECK (predicted_backorder_flag IN (0, 1)),

    classification_threshold NUMERIC(14,10) NOT NULL
        CHECK (
            classification_threshold > 0
            AND classification_threshold < 1
        ),

    model_name TEXT NOT NULL,

    risk_category TEXT NOT NULL
        CHECK (risk_category IN ('Low', 'Medium', 'High')),

    CONSTRAINT chk_prediction_flag
        CHECK (
            predicted_backorder_flag =
            CASE
                WHEN predicted_backorder_probability
                     >= classification_threshold
                THEN 1
                ELSE 0
            END
        ),

    CONSTRAINT chk_risk_category
        CHECK (
            risk_category =
            CASE
                WHEN predicted_backorder_probability < 0.10
                THEN 'Low'
                WHEN predicted_backorder_probability
                     < classification_threshold
                THEN 'Medium'
                ELSE 'High'
            END
        )

);


-- Verify prediction table columns and data types

SELECT
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns
WHERE table_schema = 'mart'
  AND table_name = 'sku_backorder_predictions'
ORDER BY ordinal_position;


-- Check that the new table is ready for import

SELECT COUNT(*) AS prediction_rows
FROM mart.sku_backorder_predictions;



SELECT
    COUNT(*) AS total_inventory_skus,
    COUNT(DISTINCT sku) AS unique_inventory_skus
FROM mart.fact_inventory;
