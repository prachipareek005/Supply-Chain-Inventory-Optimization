
-- Action 3.15: Validate Olist Sellers data

SELECT
    COUNT(*) AS total_sellers,

    COUNT(*) FILTER (
        WHERE seller_id IS NULL
           OR TRIM(seller_id) = ''
    ) AS missing_seller_ids,

    COUNT(*) FILTER (
        WHERE seller_zip_code_prefix IS NULL
           OR TRIM(seller_zip_code_prefix) = ''
    ) AS missing_zip_codes,

    COUNT(*) FILTER (
        WHERE seller_city IS NULL
           OR TRIM(seller_city) = ''
    ) AS missing_cities,

    COUNT(*) FILTER (
        WHERE seller_state IS NULL
           OR TRIM(seller_state) = ''
    ) AS missing_states,

    COUNT(*) - COUNT(DISTINCT seller_id)
        AS duplicate_seller_ids

FROM raw.olist_sellers;


-- Action 3.16: Create cleaned Olist Sellers table

CREATE TABLE IF NOT EXISTS clean.olist_sellers AS
SELECT
    TRIM(seller_id) AS seller_id,

    LPAD(TRIM(seller_zip_code_prefix), 5, '0')
        AS seller_zip_code_prefix,

    LOWER(TRIM(seller_city)) AS seller_city,

    UPPER(TRIM(seller_state)) AS seller_state

FROM raw.olist_sellers;


-- Verify cleaned Olist Sellers

SELECT
    COUNT(*) AS total_sellers,

    COUNT(*) - COUNT(DISTINCT seller_id)
        AS duplicate_seller_ids,

    COUNT(*) FILTER (
        WHERE LENGTH(seller_zip_code_prefix) <> 5
    ) AS invalid_zip_lengths,

    COUNT(*) FILTER (
        WHERE seller_city IS NULL
           OR seller_state IS NULL
    ) AS missing_locations

FROM clean.olist_sellers;


-- Action 3.17: Sellers integrity and relationship check

SELECT
    (SELECT COUNT(*)
     FROM raw.olist_sellers) AS raw_rows,

    (SELECT COUNT(*)
     FROM clean.olist_sellers) AS clean_rows,

    (SELECT COUNT(*)
     FROM clean.olist_sellers)
    -
    (SELECT COUNT(*)
     FROM raw.olist_sellers) AS row_difference,

    (SELECT COUNT(*) - COUNT(DISTINCT seller_id)
     FROM clean.olist_sellers) AS duplicate_seller_ids,

    (SELECT COUNT(*)
     FROM clean.olist_order_items i
     WHERE NOT EXISTS (
         SELECT 1
         FROM clean.olist_sellers s
         WHERE s.seller_id = i.seller_id
     )) AS unmatched_seller_references;
