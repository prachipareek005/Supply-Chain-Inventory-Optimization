
-- Action 3.18: Validate Olist Customers data

SELECT
    COUNT(*) AS total_customers,

    COUNT(*) FILTER (
        WHERE customer_id IS NULL
           OR TRIM(customer_id) = ''
    ) AS missing_customer_ids,

    COUNT(*) FILTER (
        WHERE customer_unique_id IS NULL
           OR TRIM(customer_unique_id) = ''
    ) AS missing_unique_ids,

    COUNT(*) FILTER (
        WHERE customer_zip_code_prefix IS NULL
           OR TRIM(customer_zip_code_prefix) = ''
    ) AS missing_zip_codes,

    COUNT(*) FILTER (
        WHERE customer_city IS NULL
           OR TRIM(customer_city) = ''
    ) AS missing_cities,

    COUNT(*) FILTER (
        WHERE customer_state IS NULL
           OR TRIM(customer_state) = ''
    ) AS missing_states,

    COUNT(*) - COUNT(DISTINCT customer_id)
        AS duplicate_customer_ids

FROM raw.olist_customers;


-- Action 3.19: Create cleaned Olist Customers table

CREATE TABLE IF NOT EXISTS clean.olist_customers AS
SELECT
    TRIM(customer_id) AS customer_id,

    TRIM(customer_unique_id) AS customer_unique_id,

    LPAD(TRIM(customer_zip_code_prefix), 5, '0')
        AS customer_zip_code_prefix,

    LOWER(TRIM(customer_city)) AS customer_city,

    UPPER(TRIM(customer_state)) AS customer_state

FROM raw.olist_customers;


-- Verify cleaned Olist Customers

SELECT
    COUNT(*) AS total_customers,

    COUNT(*) - COUNT(DISTINCT customer_id)
        AS duplicate_customer_ids,

    COUNT(*) FILTER (
        WHERE LENGTH(customer_zip_code_prefix) <> 5
    ) AS invalid_zip_lengths,

    COUNT(*) FILTER (
        WHERE customer_city IS NULL
           OR customer_state IS NULL
    ) AS missing_locations

FROM clean.olist_customers;


-- Action 3.20: Customers integrity and relationship check

SELECT
    (SELECT COUNT(*)
     FROM raw.olist_customers) AS raw_rows,

    (SELECT COUNT(*)
     FROM clean.olist_customers) AS clean_rows,

    (SELECT COUNT(*)
     FROM clean.olist_customers)
    -
    (SELECT COUNT(*)
     FROM raw.olist_customers) AS row_difference,

    (SELECT COUNT(*) - COUNT(DISTINCT customer_id)
     FROM clean.olist_customers) AS duplicate_customer_ids,

    (SELECT COUNT(*)
     FROM clean.olist_orders o
     WHERE NOT EXISTS (
         SELECT 1
         FROM clean.olist_customers c
         WHERE c.customer_id = o.customer_id
     )) AS unmatched_customer_references;
