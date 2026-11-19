
-- Action 3.12: Validate Olist Products numeric fields

WITH product_values AS (
    SELECT
        v.field_name,
        v.field_value
    FROM raw.olist_products p
    CROSS JOIN LATERAL (
        VALUES
            ('product_name_lenght', p.product_name_lenght),
            ('product_description_lenght', p.product_description_lenght),
            ('product_photos_qty', p.product_photos_qty),
            ('product_weight_g', p.product_weight_g),
            ('product_length_cm', p.product_length_cm),
            ('product_height_cm', p.product_height_cm),
            ('product_width_cm', p.product_width_cm)
    ) AS v(field_name, field_value)
)
SELECT
    field_name,

    COUNT(*) AS total_rows,

    COUNT(*) FILTER (
        WHERE field_value IS NULL
           OR TRIM(field_value) = ''
    ) AS missing_values,

    COUNT(*) FILTER (
        WHERE field_value IS NOT NULL
          AND TRIM(field_value) <> ''
          AND NOT pg_input_is_valid(
              field_value,
              'numeric'
          )
    ) AS invalid_numeric_values

FROM product_values
GROUP BY field_name
ORDER BY field_name;


-- Action 3.13: Create cleaned Olist Products table

CREATE TABLE IF NOT EXISTS clean.olist_products AS
SELECT
    product_id,

    NULLIF(TRIM(product_category_name), '')
        AS product_category_name,

    NULLIF(TRIM(product_name_lenght), '')::INTEGER
        AS product_name_length,

    NULLIF(TRIM(product_description_lenght), '')::INTEGER
        AS product_description_length,

    NULLIF(TRIM(product_photos_qty), '')::INTEGER
        AS product_photos_qty,

    NULLIF(TRIM(product_weight_g), '')::NUMERIC
        AS product_weight_g,

    NULLIF(TRIM(product_length_cm), '')::NUMERIC
        AS product_length_cm,

    NULLIF(TRIM(product_height_cm), '')::NUMERIC
        AS product_height_cm,

    NULLIF(TRIM(product_width_cm), '')::NUMERIC
        AS product_width_cm,

    CASE
        WHEN NULLIF(TRIM(product_category_name), '') IS NULL
        THEN 1 ELSE 0
    END AS missing_category_flag,

    CASE
        WHEN NULLIF(TRIM(product_weight_g), '') IS NULL
          OR NULLIF(TRIM(product_length_cm), '') IS NULL
          OR NULLIF(TRIM(product_height_cm), '') IS NULL
          OR NULLIF(TRIM(product_width_cm), '') IS NULL
        THEN 1 ELSE 0
    END AS missing_dimensions_flag

FROM raw.olist_products;


-- Verify cleaned Olist Products

SELECT
    COUNT(*) AS total_products,

    SUM(missing_category_flag) AS missing_categories,

    SUM(missing_dimensions_flag) AS missing_dimensions

FROM clean.olist_products;


-- Action 3.14: Final Products integrity check

SELECT
    (SELECT COUNT(*)
     FROM raw.olist_products) AS raw_rows,

    (SELECT COUNT(*)
     FROM clean.olist_products) AS clean_rows,

    (SELECT COUNT(*)
     FROM clean.olist_products)
    -
    (SELECT COUNT(*)
     FROM raw.olist_products) AS row_difference,

    (SELECT COUNT(*) - COUNT(DISTINCT product_id)
     FROM clean.olist_products) AS duplicate_product_ids,

    (SELECT COUNT(*)
     FROM clean.olist_order_items i
     WHERE NOT EXISTS (
         SELECT 1
         FROM clean.olist_products p
         WHERE p.product_id = i.product_id
     )) AS unmatched_product_references;
