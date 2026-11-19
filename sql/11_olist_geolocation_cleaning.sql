
-- Action 3.29: Validate Olist Geolocation data

SELECT
    COUNT(*) AS total_records,

    COUNT(*) FILTER (
        WHERE geolocation_zip_code_prefix IS NULL
           OR TRIM(geolocation_zip_code_prefix) = ''
    ) AS missing_zip_codes,

    COUNT(*) FILTER (
        WHERE geolocation_lat IS NULL
           OR TRIM(geolocation_lat) = ''
    ) AS missing_latitudes,

    COUNT(*) FILTER (
        WHERE geolocation_lng IS NULL
           OR TRIM(geolocation_lng) = ''
    ) AS missing_longitudes,

    COUNT(*) FILTER (
        WHERE geolocation_city IS NULL
           OR TRIM(geolocation_city) = ''
    ) AS missing_cities,

    COUNT(*) FILTER (
        WHERE geolocation_state IS NULL
           OR TRIM(geolocation_state) = ''
    ) AS missing_states,

    COUNT(*) FILTER (
        WHERE geolocation_lat IS NOT NULL
          AND TRIM(geolocation_lat) <> ''
          AND NOT pg_input_is_valid(
              geolocation_lat, 'double precision'
          )
    ) AS invalid_latitude_types,

    COUNT(*) FILTER (
        WHERE geolocation_lng IS NOT NULL
          AND TRIM(geolocation_lng) <> ''
          AND NOT pg_input_is_valid(
              geolocation_lng, 'double precision'
          )
    ) AS invalid_longitude_types

FROM raw.olist_geolocation;


-- Action 3.30: Create cleaned Olist Geolocation table

CREATE TABLE IF NOT EXISTS clean.olist_geolocation AS
SELECT
    LPAD(TRIM(geolocation_zip_code_prefix), 5, '0')
        AS geolocation_zip_code_prefix,

    NULLIF(TRIM(geolocation_lat), '')::DOUBLE PRECISION
        AS geolocation_lat,

    NULLIF(TRIM(geolocation_lng), '')::DOUBLE PRECISION
        AS geolocation_lng,

    LOWER(TRIM(geolocation_city))
        AS geolocation_city,

    UPPER(TRIM(geolocation_state))
        AS geolocation_state,

    CASE
        WHEN NULLIF(TRIM(geolocation_lat), '')::DOUBLE PRECISION
             NOT BETWEEN -90 AND 90
          OR NULLIF(TRIM(geolocation_lng), '')::DOUBLE PRECISION
             NOT BETWEEN -180 AND 180
        THEN 1 ELSE 0
    END AS invalid_coordinate_flag

FROM raw.olist_geolocation;


-- Verify cleaned Olist Geolocation

SELECT
    COUNT(*) AS total_records,

    COUNT(*) FILTER (
        WHERE invalid_coordinate_flag = 1
    ) AS invalid_coordinates,

    COUNT(*) FILTER (
        WHERE LENGTH(geolocation_zip_code_prefix) <> 5
    ) AS invalid_zip_lengths

FROM clean.olist_geolocation;


-- Action 3.31: Geolocation row and ZIP integrity

WITH zip_counts AS (
    SELECT
        geolocation_zip_code_prefix,
        COUNT(*) AS record_count
    FROM clean.olist_geolocation
    GROUP BY geolocation_zip_code_prefix
)
SELECT
    (SELECT COUNT(*)
     FROM raw.olist_geolocation) AS raw_rows,

    (SELECT COUNT(*)
     FROM clean.olist_geolocation) AS clean_rows,

    (SELECT COUNT(*)
     FROM clean.olist_geolocation)
    -
    (SELECT COUNT(*)
     FROM raw.olist_geolocation) AS row_difference,

    COUNT(*) AS unique_zip_prefixes,

    COUNT(*) FILTER (
        WHERE record_count > 1
    ) AS repeated_zip_prefixes,

    COALESCE(
        SUM(record_count - 1), 0
    ) AS extra_zip_occurrences

FROM zip_counts;


-- Action 3.32: Check exact duplicate geolocation records

WITH duplicate_counts AS (
    SELECT
        geolocation_zip_code_prefix,
        geolocation_lat,
        geolocation_lng,
        geolocation_city,
        geolocation_state,
        COUNT(*) AS record_count
    FROM clean.olist_geolocation
    GROUP BY
        geolocation_zip_code_prefix,
        geolocation_lat,
        geolocation_lng,
        geolocation_city,
        geolocation_state
)
SELECT
    SUM(record_count) AS total_records,

    COUNT(*) AS distinct_record_groups,

    COUNT(*) FILTER (
        WHERE record_count > 1
    ) AS duplicated_groups,

    SUM(record_count - 1)
        AS extra_duplicate_records

FROM duplicate_counts;


-- Action 3.33: Validate Brazilian state coverage

SELECT
    COUNT(*) AS total_records,

    COUNT(DISTINCT geolocation_state) AS distinct_states,

    COUNT(*) FILTER (
        WHERE geolocation_state NOT IN (
            'AC', 'AL', 'AP', 'AM', 'BA', 'CE',
            'DF', 'ES', 'GO', 'MA', 'MT', 'MS',
            'MG', 'PA', 'PB', 'PR', 'PE', 'PI',
            'RJ', 'RN', 'RS', 'RO', 'RR', 'SC',
            'SP', 'SE', 'TO'
        )
        OR geolocation_state IS NULL
    ) AS invalid_state_codes,

    COUNT(DISTINCT geolocation_city) AS distinct_cities,

    COUNT(DISTINCT geolocation_zip_code_prefix)
        AS distinct_zip_prefixes

FROM clean.olist_geolocation;


-- Action 3.34: Create ZIP-level geographic reference table

CREATE TABLE IF NOT EXISTS clean.olist_geolocation_zip AS

WITH zip_locations AS (
    SELECT
        geolocation_zip_code_prefix,

        geolocation_city,

        geolocation_state,

        geolocation_lat,

        geolocation_lng,

        COUNT(*) AS location_frequency

    FROM clean.olist_geolocation

    GROUP BY
        geolocation_zip_code_prefix,
        geolocation_city,
        geolocation_state,
        geolocation_lat,
        geolocation_lng
),

ranked_locations AS (
    SELECT
        *,

        ROW_NUMBER() OVER (
            PARTITION BY geolocation_zip_code_prefix
            ORDER BY
                location_frequency DESC,
                geolocation_state,
                geolocation_city,
                geolocation_lat,
                geolocation_lng
        ) AS location_rank

    FROM zip_locations
)

SELECT
    geolocation_zip_code_prefix,
    geolocation_city,
    geolocation_state,
    geolocation_lat,
    geolocation_lng

FROM ranked_locations

WHERE location_rank = 1;


-- Verify ZIP-level geographic reference table

SELECT
    COUNT(*) AS total_zip_records,

    COUNT(DISTINCT geolocation_zip_code_prefix)
        AS unique_zip_prefixes,

    COUNT(*) -
    COUNT(DISTINCT geolocation_zip_code_prefix)
        AS duplicate_zip_prefixes

FROM clean.olist_geolocation_zip;


-- Action 3.35: Customer and seller ZIP coverage

SELECT
    'Customers' AS dataset,

    COUNT(*) AS total_records,

    COUNT(*) FILTER (
        WHERE g.geolocation_zip_code_prefix IS NOT NULL
    ) AS matched_records,

    COUNT(*) FILTER (
        WHERE g.geolocation_zip_code_prefix IS NULL
    ) AS unmatched_records,

    ROUND(
        100.0 * COUNT(*) FILTER (
            WHERE g.geolocation_zip_code_prefix IS NOT NULL
        ) / NULLIF(COUNT(*), 0),
        2
    ) AS match_rate_pct

FROM clean.olist_customers c
LEFT JOIN clean.olist_geolocation_zip g
    ON c.customer_zip_code_prefix =
       g.geolocation_zip_code_prefix

UNION ALL

SELECT
    'Sellers' AS dataset,

    COUNT(*) AS total_records,

    COUNT(*) FILTER (
        WHERE g.geolocation_zip_code_prefix IS NOT NULL
    ) AS matched_records,

    COUNT(*) FILTER (
        WHERE g.geolocation_zip_code_prefix IS NULL
    ) AS unmatched_records,

    ROUND(
        100.0 * COUNT(*) FILTER (
            WHERE g.geolocation_zip_code_prefix IS NOT NULL
        ) / NULLIF(COUNT(*), 0),
        2
    ) AS match_rate_pct

FROM clean.olist_sellers s
LEFT JOIN clean.olist_geolocation_zip g
    ON s.seller_zip_code_prefix =
       g.geolocation_zip_code_prefix;


-- Action 3.36: Final Geolocation integrity check

SELECT
    (SELECT COUNT(*)
     FROM raw.olist_geolocation)
        AS raw_rows,

    (SELECT COUNT(*)
     FROM clean.olist_geolocation)
        AS clean_rows,

    (SELECT COUNT(*)
     FROM clean.olist_geolocation_zip)
        AS zip_reference_rows,

    (SELECT COUNT(DISTINCT geolocation_zip_code_prefix)
     FROM clean.olist_geolocation)
        AS distinct_clean_zip_prefixes,

    (SELECT COUNT(*) -
            COUNT(DISTINCT geolocation_zip_code_prefix)
     FROM clean.olist_geolocation_zip)
        AS duplicate_reference_zips,

    (SELECT COUNT(*)
     FROM (
         SELECT DISTINCT geolocation_zip_code_prefix
         FROM clean.olist_geolocation

         EXCEPT

         SELECT geolocation_zip_code_prefix
         FROM clean.olist_geolocation_zip
     ) missing)
        AS missing_reference_zips;
