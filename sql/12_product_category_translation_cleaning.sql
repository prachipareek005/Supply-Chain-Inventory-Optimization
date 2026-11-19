
-- Action 3.37: Validate Product Category Translation

SELECT
    COUNT(*) AS total_records,

    COUNT(*) FILTER (
        WHERE product_category_name IS NULL
           OR TRIM(product_category_name) = ''
    ) AS missing_portuguese_names,

    COUNT(*) FILTER (
        WHERE product_category_name_english IS NULL
           OR TRIM(product_category_name_english) = ''
    ) AS missing_english_names,

    COUNT(DISTINCT TRIM(product_category_name))
        AS unique_portuguese_categories,

    COUNT(*) -
    COUNT(DISTINCT TRIM(product_category_name))
        AS duplicate_portuguese_categories

FROM raw.product_category_translation;


-- Action 3.38: Create cleaned Product Category Translation

CREATE TABLE IF NOT EXISTS clean.product_category_translation AS

SELECT
    LOWER(TRIM(product_category_name))
        AS product_category_name,

    LOWER(TRIM(product_category_name_english))
        AS product_category_name_english

FROM raw.product_category_translation;


-- Verify cleaned Product Category Translation

SELECT
    COUNT(*) AS total_records,

    COUNT(DISTINCT product_category_name)
        AS unique_portuguese_categories,

    COUNT(*) -
    COUNT(DISTINCT product_category_name)
        AS duplicate_portuguese_categories,

    COUNT(*) FILTER (
        WHERE product_category_name IS NULL
           OR product_category_name_english IS NULL
    ) AS missing_category_names

FROM clean.product_category_translation;


-- Action 3.39: Product Category Translation Coverage

WITH product_categories AS (
    SELECT
        LOWER(TRIM(product_category_name))
            AS product_category_name,
        COUNT(*) AS product_count
    FROM clean.olist_products
    WHERE product_category_name IS NOT NULL
      AND TRIM(product_category_name) <> ''
    GROUP BY LOWER(TRIM(product_category_name))
)

SELECT
    COUNT(*) AS total_distinct_product_categories,

    COUNT(*) FILTER (
        WHERE t.product_category_name IS NOT NULL
    ) AS translated_categories,

    COUNT(*) FILTER (
        WHERE t.product_category_name IS NULL
    ) AS untranslated_categories,

    COALESCE(
        SUM(p.product_count) FILTER (
            WHERE t.product_category_name IS NULL
        ), 0
    ) AS products_without_translation

FROM product_categories p

LEFT JOIN clean.product_category_translation t
    ON p.product_category_name = t.product_category_name;


-- Action 3.40: Identify untranslated product categories

SELECT
    LOWER(TRIM(p.product_category_name))
        AS untranslated_category,

    COUNT(*) AS affected_products

FROM clean.olist_products p

LEFT JOIN clean.product_category_translation t
    ON LOWER(TRIM(p.product_category_name)) =
       t.product_category_name

WHERE p.product_category_name IS NOT NULL
  AND TRIM(p.product_category_name) <> ''
  AND t.product_category_name IS NULL

GROUP BY LOWER(TRIM(p.product_category_name))

ORDER BY affected_products DESC;


-- Action 3.41: Create product category-name fallback

CREATE OR REPLACE VIEW clean.olist_products_categories AS

SELECT
    p.*,

    COALESCE(
        t.product_category_name_english,
        NULLIF(LOWER(TRIM(p.product_category_name)), ''),
        'uncategorized'
    ) AS category_display_name,

    CASE
        WHEN NULLIF(TRIM(p.product_category_name), '') IS NULL
            THEN 'Missing original category'

        WHEN t.product_category_name_english IS NULL
            THEN 'Portuguese fallback'

        ELSE 'English translation'
    END AS category_translation_status

FROM clean.olist_products p

LEFT JOIN clean.product_category_translation t
    ON LOWER(TRIM(p.product_category_name)) =
       t.product_category_name;


-- Verify Action 3.41

SELECT
    COUNT(*) AS total_products,

    COUNT(*) FILTER (
        WHERE category_translation_status =
              'English translation'
    ) AS translated_products,

    COUNT(*) FILTER (
        WHERE category_translation_status =
              'Portuguese fallback'
    ) AS fallback_products,

    COUNT(*) FILTER (
        WHERE category_translation_status =
              'Missing original category'
    ) AS uncategorized_products,

    COUNT(*) FILTER (
        WHERE category_display_name IS NULL
    ) AS missing_display_names

FROM clean.olist_products_categories;


-- Action 3.42: Final Product Category Translation Integrity

SELECT
    (SELECT COUNT(*)
     FROM raw.product_category_translation)
        AS raw_translation_rows,

    (SELECT COUNT(*)
     FROM clean.product_category_translation)
        AS clean_translation_rows,

    (SELECT COUNT(*)
     FROM clean.olist_products)
        AS clean_product_rows,

    (SELECT COUNT(*)
     FROM clean.olist_products_categories)
        AS fallback_view_rows,

    (SELECT COUNT(*) -
            COUNT(DISTINCT product_id)
     FROM clean.olist_products_categories)
        AS duplicate_product_ids,

    (SELECT COUNT(*)
     FROM clean.olist_products_categories
     WHERE category_display_name IS NULL
        OR TRIM(category_display_name) = '')
        AS missing_display_names;
