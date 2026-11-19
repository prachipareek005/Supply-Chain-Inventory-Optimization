
-- Action 3.54: Validate CLU Test Dataset

SELECT
    COUNT(*) AS total_records,

    COUNT(*) FILTER (
        WHERE sku IS NULL
           OR TRIM(sku) = ''
    ) AS missing_skus,

    COUNT(*) - COUNT(DISTINCT TRIM(sku))
        AS duplicate_skus,

    COUNT(*) FILTER (
        WHERE national_inv IS NULL
           OR TRIM(national_inv) = ''
           OR NOT pg_input_is_valid(
               TRIM(national_inv), 'numeric'
           )
    ) AS invalid_inventory_values,

    COUNT(*) FILTER (
        WHERE lead_time IS NULL
           OR TRIM(lead_time) = ''
    ) AS missing_lead_times,

    COUNT(*) FILTER (
        WHERE lead_time IS NOT NULL
          AND TRIM(lead_time) <> ''
          AND NOT pg_input_is_valid(
              TRIM(lead_time), 'numeric'
          )
    ) AS invalid_lead_time_values,

    COUNT(*) FILTER (
        WHERE EXISTS (
            SELECT 1
            FROM raw.clu_train tr
            WHERE TRIM(tr.sku) = TRIM(t.sku)
        )
    ) AS overlapping_training_skus

FROM raw.clu_test t;


-- Action 3.55: CLU Test inventory anomaly investigation

SELECT
    COUNT(*) AS total_records,

    COUNT(*) FILTER (
        WHERE NULLIF(TRIM(national_inv), '')::NUMERIC < 0
    ) AS negative_inventory_records,

    COUNT(*) FILTER (
        WHERE lead_time IS NULL
           OR TRIM(lead_time) = ''
    ) AS missing_lead_times,

    COUNT(*) FILTER (
        WHERE NULLIF(TRIM(lead_time), '')::NUMERIC = 0
    ) AS zero_lead_times,

    COUNT(*) FILTER (
        WHERE NULLIF(TRIM(perf_6_month_avg), '')::NUMERIC = -99
    ) AS supplier_6m_sentinels,

    COUNT(*) FILTER (
        WHERE NULLIF(TRIM(perf_12_month_avg), '')::NUMERIC = -99
    ) AS supplier_12m_sentinels

FROM raw.clu_test;


-- Action 3.56: Validate remaining CLU Test numeric fields

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

FROM raw.clu_test t

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


-- Action 3.57: Validate CLU Test categorical risk flags

SELECT
    v.column_name,

    COUNT(*) FILTER (
        WHERE TRIM(v.column_value) = '1'
    ) AS one_count,

    COUNT(*) FILTER (
        WHERE TRIM(v.column_value) = '0'
    ) AS zero_count,

    COUNT(*) FILTER (
        WHERE v.column_value IS NULL
           OR TRIM(v.column_value) = ''
    ) AS missing_values,

    COUNT(*) FILTER (
        WHERE v.column_value IS NOT NULL
          AND TRIM(v.column_value) <> ''
          AND TRIM(v.column_value) NOT IN ('0', '1')
    ) AS invalid_labels

FROM raw.clu_test t

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


-- Action 3.58: Create cleaned CLU Test table

CREATE TABLE IF NOT EXISTS clean.clu_test AS
SELECT
    -- Product identifier
    TRIM(sku) AS sku,

    -- Inventory and lead time
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

    -- Risk indicator (0/1)
    CASE TRIM(potential_issue)
        WHEN '1' THEN TRUE
        WHEN '0' THEN FALSE
        ELSE NULL
    END AS potential_issue,

    -- Overdue quantities
    NULLIF(TRIM(pieces_past_due), '')::NUMERIC
        AS pieces_past_due,

    -- Preserve original supplier performance values
    NULLIF(TRIM(perf_6_month_avg), '')::NUMERIC
        AS perf_6_month_avg_raw,

    NULLIF(TRIM(perf_12_month_avg), '')::NUMERIC
        AS perf_12_month_avg_raw,

    -- Replace -99 with NULL for analysis
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

    -- Boolean risk indicators (0/1)
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

    -- Data quality indicators
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

FROM raw.clu_test;


-- Action 3.58: Verify cleaned CLU Test table

SELECT
    COUNT(*) AS total_records,

    COUNT(DISTINCT sku) AS unique_skus,

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
        WHERE potential_issue IS NULL
           OR deck_risk IS NULL
           OR oe_constraint IS NULL
           OR ppap_risk IS NULL
           OR stop_auto_buy IS NULL
           OR rev_stop IS NULL
    ) AS records_with_null_risk_flags

FROM clean.clu_test;


-- Action 3.59: CLU Test Record Integrity

SELECT
    (SELECT COUNT(*)
     FROM raw.clu_test)
        AS raw_rows,

    (SELECT COUNT(*)
     FROM clean.clu_test)
        AS clean_rows,

    (SELECT COUNT(*)
     FROM clean.clu_test)
    -
    (SELECT COUNT(*)
     FROM raw.clu_test)
        AS row_difference,

    (SELECT COUNT(*) -
            COUNT(DISTINCT sku)
     FROM clean.clu_test)
        AS duplicate_skus,

    (SELECT COUNT(*)
     FROM clean.clu_test c
     WHERE NOT EXISTS (
         SELECT 1
         FROM raw.clu_test r
         WHERE TRIM(r.sku) = c.sku
     ))
        AS unmatched_clean_skus,

    (SELECT COUNT(*)
     FROM raw.clu_test r
     WHERE NOT EXISTS (
         SELECT 1
         FROM clean.clu_test c
         WHERE c.sku = TRIM(r.sku)
     ))
        AS missing_clean_skus,

    (SELECT COUNT(*)
     FROM clean.clu_test t
     WHERE EXISTS (
         SELECT 1
         FROM clean.clu_train tr
         WHERE tr.sku = t.sku
     ))
        AS overlapping_training_skus;


-- Action 3.60: Verify CLU Test numeric conversions

WITH comparison AS (
    SELECT
        r.sku,

        (
            c.national_inv IS DISTINCT FROM
                NULLIF(TRIM(r.national_inv), '')::NUMERIC

            OR c.lead_time IS DISTINCT FROM
                NULLIF(TRIM(r.lead_time), '')::NUMERIC

            OR c.in_transit_qty IS DISTINCT FROM
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

            OR c.perf_6_month_avg IS DISTINCT FROM
                NULLIF(
                    NULLIF(TRIM(r.perf_6_month_avg), '')::NUMERIC,
                    -99
                )

            OR c.perf_12_month_avg IS DISTINCT FROM
                NULLIF(
                    NULLIF(TRIM(r.perf_12_month_avg), '')::NUMERIC,
                    -99
                )
        ) AS has_numeric_mismatch

    FROM raw.clu_test r
    JOIN clean.clu_test c
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


-- Action 3.61: Verify CLU Test Boolean conversions

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

FROM raw.clu_test r

JOIN clean.clu_test c
    ON TRIM(r.sku) = c.sku;


-- Action 3.62: Final CLU Test Quality Check

SELECT
    COUNT(*) AS total_records,

    COUNT(*) - COUNT(DISTINCT sku)
        AS duplicate_skus,

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

    (
        SELECT COUNT(*)
        FROM clean.clu_test t
        WHERE EXISTS (
            SELECT 1
            FROM clean.clu_train tr
            WHERE tr.sku = t.sku
        )
    ) AS overlapping_training_skus

FROM clean.clu_test;
