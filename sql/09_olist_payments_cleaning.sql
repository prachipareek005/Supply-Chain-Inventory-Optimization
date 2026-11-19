
-- Action 3.21: Validate Olist Payments data

SELECT
    COUNT(*) AS total_payments,

    COUNT(*) FILTER (
        WHERE order_id IS NULL OR TRIM(order_id) = ''
    ) AS missing_order_ids,

    COUNT(*) FILTER (
        WHERE payment_type IS NULL OR TRIM(payment_type) = ''
    ) AS missing_payment_types,

    COUNT(*) FILTER (
        WHERE payment_sequential IS NULL
           OR TRIM(payment_sequential) = ''
           OR NOT pg_input_is_valid(
               payment_sequential, 'integer'
           )
    ) AS invalid_payment_sequences,

    COUNT(*) FILTER (
        WHERE payment_installments IS NULL
           OR TRIM(payment_installments) = ''
           OR NOT pg_input_is_valid(
               payment_installments, 'integer'
           )
    ) AS invalid_installments,

    COUNT(*) FILTER (
        WHERE payment_value IS NULL
           OR TRIM(payment_value) = ''
           OR NOT pg_input_is_valid(
               payment_value, 'numeric'
           )
    ) AS invalid_payment_values

FROM raw.olist_order_payments;


-- Action 3.22: Create cleaned Olist Payments table

CREATE TABLE IF NOT EXISTS clean.olist_order_payments AS
SELECT
    TRIM(order_id) AS order_id,

    NULLIF(TRIM(payment_sequential), '')::INTEGER
        AS payment_sequential,

    LOWER(TRIM(payment_type)) AS payment_type,

    NULLIF(TRIM(payment_installments), '')::INTEGER
        AS payment_installments,

    NULLIF(TRIM(payment_value), '')::NUMERIC(14,2)
        AS payment_value,

    CASE
        WHEN NULLIF(TRIM(payment_value), '')::NUMERIC = 0
        THEN 1 ELSE 0
    END AS zero_payment_flag,

    CASE
        WHEN NULLIF(TRIM(payment_value), '')::NUMERIC < 0
        THEN 1 ELSE 0
    END AS negative_payment_flag

FROM raw.olist_order_payments;


-- Verify cleaned Olist Payments

SELECT
    COUNT(*) AS total_payments,

    SUM(zero_payment_flag) AS zero_payments,

    SUM(negative_payment_flag) AS negative_payments,

    MAX(payment_value) AS maximum_payment

FROM clean.olist_order_payments;


-- Action 3.23: Payments integrity and relationship check

SELECT
    (SELECT COUNT(*)
     FROM raw.olist_order_payments) AS raw_rows,

    (SELECT COUNT(*)
     FROM clean.olist_order_payments) AS clean_rows,

    (SELECT COUNT(*)
     FROM clean.olist_order_payments)
    -
    (SELECT COUNT(*)
     FROM raw.olist_order_payments) AS row_difference,

    (SELECT COUNT(*)
     FROM (
         SELECT order_id, payment_sequential
         FROM clean.olist_order_payments
         GROUP BY order_id, payment_sequential
         HAVING COUNT(*) > 1
     ) duplicates) AS duplicate_payment_keys,

    (SELECT COUNT(*)
     FROM clean.olist_order_payments p
     WHERE NOT EXISTS (
         SELECT 1
         FROM clean.olist_orders o
         WHERE o.order_id = p.order_id
     )) AS unmatched_order_references;
