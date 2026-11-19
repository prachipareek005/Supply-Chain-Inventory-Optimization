
-- Action 3.43: Validate CLU training dataset

SELECT
    COUNT(*) AS total_records,

    COUNT(*) FILTER (
        WHERE sku IS NULL
           OR TRIM(sku) = ''
    ) AS missing_skus,

    COUNT(*) -
    COUNT(DISTINCT TRIM(sku))
        AS duplicate_skus,

    COUNT(*) FILTER (
        WHERE national_inv IS NULL
           OR TRIM(national_inv) = ''
           OR NOT pg_input_is_valid(
               TRIM(national_inv), 'numeric'
           )
    ) AS invalid_inventory_types,

    COUNT(*) FILTER (
        WHERE lead_time IS NOT NULL
          AND TRIM(lead_time) <> ''
          AND NOT pg_input_is_valid(
              TRIM(lead_time), 'numeric'
          )
    ) AS invalid_lead_time_types,

    COUNT(*) FILTER (
        WHERE lead_time IS NULL
           OR TRIM(lead_time) = ''
    ) AS missing_lead_times,

    COUNT(*) FILTER (
        WHERE went_on_backorder IS NULL
           OR TRIM(went_on_backorder) = ''
    ) AS missing_backorder_labels

FROM raw.clu_train;


-- Action 3.44: CLU inventory anomaly investigation

SELECT
    COUNT(*) AS total_records,

    COUNT(*) FILTER (
        WHERE national_inv::NUMERIC < 0
    ) AS negative_inventory_records,

    COUNT(*) FILTER (
        WHERE lead_time IS NULL
           OR TRIM(lead_time) = ''
    ) AS missing_lead_times,

    COUNT(*) FILTER (
        WHERE NULLIF(TRIM(lead_time), '')::NUMERIC = 0
    ) AS zero_lead_times,

    COUNT(*) FILTER (
        WHERE perf_6_month_avg::NUMERIC = -99
    ) AS supplier_perf_6m_sentinel,

    COUNT(*) FILTER (
        WHERE perf_12_month_avg::NUMERIC = -99
    ) AS supplier_perf_12m_sentinel

FROM raw.clu_train;


-- Action 3.45: Validate CLU backorder labels

SELECT
    LOWER(TRIM(went_on_backorder))
        AS backorder_label,

    COUNT(*) AS total_records,

    ROUND(
        100.0 * COUNT(*) /
        SUM(COUNT(*)) OVER (),
        2
    ) AS percentage_of_records

FROM raw.clu_train

GROUP BY LOWER(TRIM(went_on_backorder))

ORDER BY total_records DESC;


-- Action 3.46: Validate CLU numerical columns

SELECT
    v.column_name,

    COUNT(*) FILTER (
        WHERE v.column_value IS NULL
           OR TRIM(v.column_value) = ''
    ) AS missing_values,

    COUNT(*) FILTER (
        WHERE v.column_value IS NOT NULL
          AND TRIM(v.column_value) <> ''
          AND NOT pg_input_is_valid(
              TRIM(v.column_value), 'numeric'
          )
    ) AS invalid_numeric_values

FROM raw.clu_train t

CROSS JOIN LATERAL (
    VALUES
        ('in_transit_qty', t.in_transit_qty),
        ('forecast_3_month', t.forecast_3_month),
        ('forecast_6_month', t.forecast_6_month),
        ('forecast_9_month', t.forecast_9_month),
        ('sales_1_month', t.sales_1_month),
        ('sales_3_month', t.sales_3_month),
        ('sales_6_month', t.sales_6_month),
        ('sales_9_month', t.sales_9_month),
        ('min_bank', t.min_bank),
        ('pieces_past_due', t.pieces_past_due),
        ('perf_6_month_avg', t.perf_6_month_avg),
        ('perf_12_month_avg', t.perf_12_month_avg),
        ('local_bo_qty', t.local_bo_qty)
) AS v(column_name, column_value)

GROUP BY v.column_name

ORDER BY v.column_name;


-- Action 3.47: Validate CLU categorical risk flags

SELECT
    v.column_name,

    COUNT(*) FILTER (
        WHERE LOWER(TRIM(v.column_value)) = 'yes'
    ) AS yes_count,

    COUNT(*) FILTER (
        WHERE LOWER(TRIM(v.column_value)) = 'no'
    ) AS no_count,

    COUNT(*) FILTER (
        WHERE v.column_value IS NULL
           OR TRIM(v.column_value) = ''
    ) AS missing_values,

    COUNT(*) FILTER (
        WHERE v.column_value IS NOT NULL
          AND TRIM(v.column_value) <> ''
          AND LOWER(TRIM(v.column_value))
              NOT IN ('yes', 'no')
    ) AS invalid_labels

FROM raw.clu_train t

CROSS JOIN LATERAL (
    VALUES
        ('potential_issue', t.potential_issue),
        ('deck_risk', t.deck_risk),
        ('oe_constraint', t.oe_constraint),
        ('ppap_risk', t.ppap_risk),
        ('stop_auto_buy', t.stop_auto_buy),
        ('rev_stop', t.rev_stop)
) AS v(column_name, column_value)

GROUP BY v.column_name
ORDER BY v.column_name;


-- Action 3.48: Create cleaned CLU training table

CREATE TABLE IF NOT EXISTS clean.clu_train AS

SELECT
    -- Product identifier
    TRIM(sku) AS sku,

    -- Inventory and supplier lead time
    NULLIF(TRIM(national_inv), '')::NUMERIC
        AS national_inv,

    NULLIF(TRIM(lead_time), '')::NUMERIC
        AS lead_time,

    NULLIF(TRIM(in_transit_qty), '')::NUMERIC
        AS in_transit_qty,

    -- Demand forecasts
    NULLIF(TRIM(forecast_3_month), '')::NUMERIC
        AS forecast_3_month,

    NULLIF(TRIM(forecast_6_month), '')::NUMERIC
        AS forecast_6_month,

    NULLIF(TRIM(forecast_9_month), '')::NUMERIC
        AS forecast_9_month,

    -- Historical sales
    NULLIF(TRIM(sales_1_month), '')::NUMERIC
        AS sales_1_month,

    NULLIF(TRIM(sales_3_month), '')::NUMERIC
        AS sales_3_month,

    NULLIF(TRIM(sales_6_month), '')::NUMERIC
        AS sales_6_month,

    NULLIF(TRIM(sales_9_month), '')::NUMERIC
        AS sales_9_month,

    -- Minimum stock
    NULLIF(TRIM(min_bank), '')::NUMERIC
        AS min_bank,

-- Corrected CLU risk-flag conversions

CASE TRIM(potential_issue)
    WHEN '1' THEN TRUE
    WHEN '0' THEN FALSE
    ELSE NULL
END AS potential_issue,

CASE TRIM(deck_risk)
    WHEN '1' THEN TRUE
    WHEN '0' THEN FALSE
    ELSE NULL
END AS deck_risk,

CASE TRIM(oe_constraint)
    WHEN '1' THEN TRUE
    WHEN '0' THEN FALSE
    ELSE NULL
END AS oe_constraint,

CASE TRIM(ppap_risk)
    WHEN '1' THEN TRUE
    WHEN '0' THEN FALSE
    ELSE NULL
END AS ppap_risk,

CASE TRIM(stop_auto_buy)
    WHEN '1' THEN TRUE
    WHEN '0' THEN FALSE
    ELSE NULL
END AS stop_auto_buy,

CASE TRIM(rev_stop)
    WHEN '1' THEN TRUE
    WHEN '0' THEN FALSE
    ELSE NULL
END AS rev_stop,

    -- Risk indicator
    CASE
        WHEN LOWER(TRIM(potential_issue)) = 'yes'
            THEN TRUE
        WHEN LOWER(TRIM(potential_issue)) = 'no'
            THEN FALSE
        ELSE NULL
    END AS potential_issue,

    -- Overdue quantities
    NULLIF(TRIM(pieces_past_due), '')::NUMERIC
        AS pieces_past_due,

    -- Preserve original supplier performance
    NULLIF(TRIM(perf_6_month_avg), '')::NUMERIC
        AS perf_6_month_avg_raw,

    NULLIF(TRIM(perf_12_month_avg), '')::NUMERIC
        AS perf_12_month_avg_raw,

    -- Convert -99 sentinel values to NULL
    NULLIF(
        NULLIF(TRIM(perf_6_month_avg), '')::NUMERIC,
        -99
    ) AS perf_6_month_avg,

    NULLIF(
        NULLIF(TRIM(perf_12_month_avg), '')::NUMERIC,
        -99
    ) AS perf_12_month_avg,

    -- Local backorder quantity
    NULLIF(TRIM(local_bo_qty), '')::NUMERIC
        AS local_bo_qty,

    -- Categorical risk flags
    CASE LOWER(TRIM(deck_risk))
        WHEN 'yes' THEN TRUE
        WHEN 'no' THEN FALSE
        ELSE NULL
    END AS deck_risk,

    CASE LOWER(TRIM(oe_constraint))
        WHEN 'yes' THEN TRUE
        WHEN 'no' THEN FALSE
        ELSE NULL
    END AS oe_constraint,

    CASE LOWER(TRIM(ppap_risk))
        WHEN 'yes' THEN TRUE
        WHEN 'no' THEN FALSE
        ELSE NULL
    END AS ppap_risk,

    CASE LOWER(TRIM(stop_auto_buy))
        WHEN 'yes' THEN TRUE
        WHEN 'no' THEN FALSE
        ELSE NULL
    END AS stop_auto_buy,

    CASE LOWER(TRIM(rev_stop))
        WHEN 'yes' THEN TRUE
        WHEN 'no' THEN FALSE
        ELSE NULL
    END AS rev_stop,

    -- Backorder target
    
CASE TRIM(went_on_backorder)
    WHEN '1' THEN TRUE
    WHEN '0' THEN FALSE
    ELSE NULL
END AS went_on_backorder,

    -- Data quality flags
    CASE
        WHEN NULLIF(TRIM(national_inv), '')::NUMERIC < 0
            THEN 1 ELSE 0
    END AS negative_inventory_flag,

    CASE
        WHEN NULLIF(TRIM(lead_time), '') IS NULL
            THEN 1 ELSE 0
    END AS missing_lead_time_flag,

    CASE
        WHEN NULLIF(TRIM(lead_time), '')::NUMERIC = 0
            THEN 1 ELSE 0
    END AS zero_lead_time_flag,

    CASE
        WHEN NULLIF(TRIM(perf_6_month_avg), '')::NUMERIC = -99
            THEN 1 ELSE 0
    END AS perf_6m_sentinel_flag,

    CASE
        WHEN NULLIF(TRIM(perf_12_month_avg), '')::NUMERIC = -99
            THEN 1 ELSE 0
    END AS perf_12m_sentinel_flag

FROM raw.clu_train;


-- Action 3.48: Verify cleaned CLU training data

SELECT
    COUNT(*) AS total_records,

    COUNT(DISTINCT sku) AS unique_skus,

    SUM(negative_inventory_flag)
        AS negative_inventory_records,

    SUM(missing_lead_time_flag)
        AS missing_lead_times,

    SUM(zero_lead_time_flag)
        AS zero_lead_times,

    SUM(perf_6m_sentinel_flag)
        AS supplier_6m_sentinels,

    SUM(perf_12m_sentinel_flag)
        AS supplier_12m_sentinels,

    COUNT(*) FILTER (
        WHERE went_on_backorder = TRUE
    ) AS backorder_yes,

    COUNT(*) FILTER (
        WHERE went_on_backorder = FALSE
    ) AS backorder_no

FROM clean.clu_train;


-- Action 3.49: CLU Training Record Integrity

SELECT
    (SELECT COUNT(*)
     FROM raw.clu_train)
        AS raw_rows,

    (SELECT COUNT(*)
     FROM clean.clu_train)
        AS clean_rows,

    (SELECT COUNT(*)
     FROM clean.clu_train)
    -
    (SELECT COUNT(*)
     FROM raw.clu_train)
        AS row_difference,

    (SELECT COUNT(*) -
            COUNT(DISTINCT sku)
     FROM clean.clu_train)
        AS duplicate_skus,

    (SELECT COUNT(*)
     FROM clean.clu_train c
     WHERE NOT EXISTS (
         SELECT 1
         FROM raw.clu_train r
         WHERE TRIM(r.sku) = c.sku
     ))
        AS unmatched_clean_skus,

    (SELECT COUNT(*)
     FROM raw.clu_train r
     WHERE NOT EXISTS (
         SELECT 1
         FROM clean.clu_train c
         WHERE c.sku = TRIM(r.sku)
     ))
        AS missing_clean_skus;


-- Action 3.50: Validate CLU cleaned value conversions

SELECT
    COUNT(*) AS compared_records,

    COUNT(*) FILTER (
        WHERE c.national_inv IS DISTINCT FROM
              NULLIF(TRIM(r.national_inv), '')::NUMERIC
    ) AS inventory_mismatches,

    COUNT(*) FILTER (
        WHERE c.lead_time IS DISTINCT FROM
              NULLIF(TRIM(r.lead_time), '')::NUMERIC
    ) AS lead_time_mismatches,

    COUNT(*) FILTER (
        WHERE c.perf_6_month_avg IS DISTINCT FROM
              NULLIF(
                  NULLIF(TRIM(r.perf_6_month_avg), '')::NUMERIC,
                  -99
              )
    ) AS supplier_6m_mismatches,

    COUNT(*) FILTER (
        WHERE c.perf_12_month_avg IS DISTINCT FROM
              NULLIF(
                  NULLIF(TRIM(r.perf_12_month_avg), '')::NUMERIC,
                  -99
              )
    ) AS supplier_12m_mismatches,

    COUNT(*) FILTER (
        WHERE c.went_on_backorder IS DISTINCT FROM
              CASE LOWER(TRIM(r.went_on_backorder))
                  WHEN 'yes' THEN TRUE
                  WHEN 'no' THEN FALSE
                  ELSE NULL
              END
    ) AS backorder_label_mismatches

FROM raw.clu_train r

JOIN clean.clu_train c
    ON TRIM(r.sku) = c.sku;


-- Action 3.51: Verify cleaned CLU risk flags

SELECT
    COUNT(*) AS compared_records,

    COUNT(*) FILTER (
        WHERE c.potential_issue IS DISTINCT FROM
            (LOWER(TRIM(r.potential_issue)) = 'yes')
    ) AS potential_issue_mismatches,

    COUNT(*) FILTER (
        WHERE c.deck_risk IS DISTINCT FROM
            (LOWER(TRIM(r.deck_risk)) = 'yes')
    ) AS deck_risk_mismatches,

    COUNT(*) FILTER (
        WHERE c.oe_constraint IS DISTINCT FROM
            (LOWER(TRIM(r.oe_constraint)) = 'yes')
    ) AS oe_constraint_mismatches,

    COUNT(*) FILTER (
        WHERE c.ppap_risk IS DISTINCT FROM
            (LOWER(TRIM(r.ppap_risk)) = 'yes')
    ) AS ppap_risk_mismatches,

    COUNT(*) FILTER (
        WHERE c.stop_auto_buy IS DISTINCT FROM
            (LOWER(TRIM(r.stop_auto_buy)) = 'yes')
    ) AS stop_auto_buy_mismatches,

    COUNT(*) FILTER (
        WHERE c.rev_stop IS DISTINCT FROM
            (LOWER(TRIM(r.rev_stop)) = 'yes')
    ) AS rev_stop_mismatches

FROM raw.clu_train r

JOIN clean.clu_train c
    ON TRIM(r.sku) = c.sku;


-- Diagnose CLU risk flag conversion mismatch

SELECT
    r.potential_issue AS raw_value,
    c.potential_issue AS clean_value,
    COUNT(*) AS record_count
FROM raw.clu_train r
JOIN clean.clu_train c
    ON TRIM(r.sku) = c.sku
GROUP BY
    r.potential_issue,
    c.potential_issue
ORDER BY record_count DESC;


-- Diagnose all six CLU risk flags

SELECT
    v.column_name,
    TRIM(v.raw_value) AS raw_value,
    COUNT(*) AS record_count

FROM raw.clu_train t

CROSS JOIN LATERAL (
    VALUES
        ('potential_issue', t.potential_issue),
        ('deck_risk', t.deck_risk),
        ('oe_constraint', t.oe_constraint),
        ('ppap_risk', t.ppap_risk),
        ('stop_auto_buy', t.stop_auto_buy),
        ('rev_stop', t.rev_stop)
) AS v(column_name, raw_value)

GROUP BY
    v.column_name,
    TRIM(v.raw_value)

ORDER BY
    v.column_name,
    raw_value;


-- Fix Action 3.51: Correct CLU risk flag conversions

UPDATE clean.clu_train c
SET
    potential_issue =
        TRIM(r.potential_issue) = '1',

    deck_risk =
        TRIM(r.deck_risk) = '1',

    oe_constraint =
        TRIM(r.oe_constraint) = '1',

    ppap_risk =
        TRIM(r.ppap_risk) = '1',

    stop_auto_buy =
        TRIM(r.stop_auto_buy) = '1',

    rev_stop =
        TRIM(r.rev_stop) = '1'

FROM raw.clu_train r
WHERE c.sku = TRIM(r.sku)
  AND TRIM(r.potential_issue) IN ('0', '1')
  AND TRIM(r.deck_risk) IN ('0', '1')
  AND TRIM(r.oe_constraint) IN ('0', '1')
  AND TRIM(r.ppap_risk) IN ('0', '1')
  AND TRIM(r.stop_auto_buy) IN ('0', '1')
  AND TRIM(r.rev_stop) IN ('0', '1');


-- Verify corrected CLU risk flags

SELECT
    COUNT(*) AS total_records,

    COUNT(*) FILTER (
        WHERE potential_issue IS NULL
           OR deck_risk IS NULL
           OR oe_constraint IS NULL
           OR ppap_risk IS NULL
           OR stop_auto_buy IS NULL
           OR rev_stop IS NULL
    ) AS records_with_null_risk_flags,

    COUNT(*) FILTER (
        WHERE potential_issue = TRUE
    ) AS potential_issue_true,

    COUNT(*) FILTER (
        WHERE deck_risk = TRUE
    ) AS deck_risk_true,

    COUNT(*) FILTER (
        WHERE oe_constraint = TRUE
    ) AS oe_constraint_true,

    COUNT(*) FILTER (
        WHERE ppap_risk = TRUE
    ) AS ppap_risk_true

FROM clean.clu_train;


-- Verify the six corrected CLU risk flags

SELECT
    COUNT(*) AS total_records,

    COUNT(*) FILTER (
        WHERE potential_issue IS NULL
           OR deck_risk IS NULL
           OR oe_constraint IS NULL
           OR ppap_risk IS NULL
           OR stop_auto_buy IS NULL
           OR rev_stop IS NULL
    ) AS records_with_null_flags

FROM clean.clu_train;


-- Action 3.51: Final risk-flag verification

SELECT
    COUNT(*) AS compared_records,

    COUNT(*) FILTER (
        WHERE c.potential_issue IS DISTINCT FROM
              (TRIM(r.potential_issue) = '1')
    ) AS potential_issue_mismatches,

    COUNT(*) FILTER (
        WHERE c.deck_risk IS DISTINCT FROM
              (TRIM(r.deck_risk) = '1')
    ) AS deck_risk_mismatches,

    COUNT(*) FILTER (
        WHERE c.oe_constraint IS DISTINCT FROM
              (TRIM(r.oe_constraint) = '1')
    ) AS oe_constraint_mismatches,

    COUNT(*) FILTER (
        WHERE c.ppap_risk IS DISTINCT FROM
              (TRIM(r.ppap_risk) = '1')
    ) AS ppap_risk_mismatches,

    COUNT(*) FILTER (
        WHERE c.stop_auto_buy IS DISTINCT FROM
              (TRIM(r.stop_auto_buy) = '1')
    ) AS stop_auto_buy_mismatches,

    COUNT(*) FILTER (
        WHERE c.rev_stop IS DISTINCT FROM
              (TRIM(r.rev_stop) = '1')
    ) AS rev_stop_mismatches

FROM raw.clu_train r

JOIN clean.clu_train c
    ON TRIM(r.sku) = c.sku;


-- Action 3.52: Verify remaining CLU numerical conversions

WITH comparison AS (
    SELECT
        r.sku,

        (
            c.in_transit_qty IS DISTINCT FROM
                NULLIF(TRIM(r.in_transit_qty), '')::NUMERIC

            OR c.forecast_3_month IS DISTINCT FROM
                NULLIF(TRIM(r.forecast_3_month), '')::NUMERIC

            OR c.forecast_6_month IS DISTINCT FROM
                NULLIF(TRIM(r.forecast_6_month), '')::NUMERIC

            OR c.forecast_9_month IS DISTINCT FROM
                NULLIF(TRIM(r.forecast_9_month), '')::NUMERIC

            OR c.sales_1_month IS DISTINCT FROM
                NULLIF(TRIM(r.sales_1_month), '')::NUMERIC

            OR c.sales_3_month IS DISTINCT FROM
                NULLIF(TRIM(r.sales_3_month), '')::NUMERIC

            OR c.sales_6_month IS DISTINCT FROM
                NULLIF(TRIM(r.sales_6_month), '')::NUMERIC

            OR c.sales_9_month IS DISTINCT FROM
                NULLIF(TRIM(r.sales_9_month), '')::NUMERIC

            OR c.min_bank IS DISTINCT FROM
                NULLIF(TRIM(r.min_bank), '')::NUMERIC

            OR c.pieces_past_due IS DISTINCT FROM
                NULLIF(TRIM(r.pieces_past_due), '')::NUMERIC

            OR c.local_bo_qty IS DISTINCT FROM
                NULLIF(TRIM(r.local_bo_qty), '')::NUMERIC
        ) AS has_numeric_mismatch

    FROM raw.clu_train r
    JOIN clean.clu_train c
        ON TRIM(r.sku) = c.sku
)

SELECT
    COUNT(*) AS compared_records,

    COUNT(*) FILTER (
        WHERE has_numeric_mismatch
    ) AS records_with_numeric_mismatches,

    COUNT(*) FILTER (
        WHERE NOT has_numeric_mismatch
    ) AS fully_matched_records

FROM comparison;


-- Action 3.53: Final CLU Training Quality Check

SELECT
    COUNT(*) AS total_records,

    COUNT(*) - COUNT(DISTINCT sku)
        AS duplicate_skus,

    COUNT(*) FILTER (
        WHERE went_on_backorder IS NULL
    ) AS missing_backorder_labels,

    COUNT(*) FILTER (
        WHERE potential_issue IS NULL
           OR deck_risk IS NULL
           OR oe_constraint IS NULL
           OR ppap_risk IS NULL
           OR stop_auto_buy IS NULL
           OR rev_stop IS NULL
    ) AS records_with_missing_risk_flags,

    COALESCE(SUM(negative_inventory_flag), 0)
        AS negative_inventory_records,

    COALESCE(SUM(missing_lead_time_flag), 0)
        AS missing_lead_times,

    COALESCE(SUM(zero_lead_time_flag), 0)
        AS zero_lead_times,

    COALESCE(SUM(perf_6m_sentinel_flag), 0)
        AS supplier_6m_sentinels,

    COALESCE(SUM(perf_12m_sentinel_flag), 0)
        AS supplier_12m_sentinels,

    COUNT(*) FILTER (
        WHERE went_on_backorder = TRUE
    ) AS backorder_yes,

    COUNT(*) FILTER (
        WHERE went_on_backorder = FALSE
    ) AS backorder_no

FROM clean.clu_train;


-- Diagnose CLU training backorder target

SELECT
    r.went_on_backorder AS raw_label,
    c.went_on_backorder AS cleaned_label,
    COUNT(*) AS record_count

FROM raw.clu_train r

JOIN clean.clu_train c
    ON TRIM(r.sku) = c.sku

GROUP BY
    r.went_on_backorder,
    c.went_on_backorder

ORDER BY record_count DESC;


-- Fix CLU training backorder labels

UPDATE clean.clu_train c
SET went_on_backorder =
    CASE TRIM(r.went_on_backorder)
        WHEN '1' THEN TRUE
        WHEN '0' THEN FALSE
        ELSE NULL
    END
FROM raw.clu_train r
WHERE c.sku = TRIM(r.sku);


-- Verify corrected backorder labels

SELECT
    COUNT(*) AS total_records,

    COUNT(*) FILTER (
        WHERE went_on_backorder = TRUE
    ) AS backorder_yes,

    COUNT(*) FILTER (
        WHERE went_on_backorder = FALSE
    ) AS backorder_no,

    COUNT(*) FILTER (
        WHERE went_on_backorder IS NULL
    ) AS missing_labels

FROM clean.clu_train;
