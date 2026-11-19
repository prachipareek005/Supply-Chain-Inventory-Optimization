
-- Phase 2, Step 4
-- Action 4.4: Create Olist order-item analytics view

CREATE OR REPLACE VIEW mart.fact_order_items AS

SELECT
    -- Transaction identifiers
    oi.order_id,
    oi.order_item_id,
    oi.product_id,
    oi.seller_id,

    -- Financial measures
    oi.price AS item_sales_value,
    oi.freight_value,
    oi.price + oi.freight_value
        AS item_total_value,

    -- Shipping deadline
    oi.shipping_limit_date,

    -- Product attributes
    p.product_weight_g,
    p.product_length_cm,
    p.product_height_cm,
    p.product_width_cm,

    -- Category information
    p.product_category_name,

    COALESCE(
        pc.category_display_name,
        'uncategorized'
    ) AS category_display_name,

    pc.category_translation_status,

    -- Seller geography
    s.seller_city,
    s.seller_state,
    s.seller_zip_code_prefix,

    -- Data-quality indicators
    CASE
        WHEN p.product_id IS NULL
        THEN 1 ELSE 0
    END AS missing_product_flag,

    CASE
        WHEN s.seller_id IS NULL
        THEN 1 ELSE 0
    END AS missing_seller_flag

FROM clean.olist_order_items oi

LEFT JOIN clean.olist_products p
    ON oi.product_id = p.product_id

LEFT JOIN clean.olist_products_categories pc
    ON oi.product_id = pc.product_id

LEFT JOIN clean.olist_sellers s
    ON oi.seller_id = s.seller_id;


-- Action 4.4: Verify order-item analytics view

SELECT
    COUNT(*) AS total_rows,

    COUNT(DISTINCT (order_id, order_item_id))
        AS unique_order_item_keys,

    COUNT(*) -
    COUNT(DISTINCT (order_id, order_item_id))
        AS duplicate_order_item_keys,

    COALESCE(SUM(missing_product_flag), 0)
        AS missing_products,

    COALESCE(SUM(missing_seller_flag), 0)
        AS missing_sellers,

    COUNT(*) FILTER (
        WHERE category_display_name IS NULL
           OR TRIM(category_display_name) = ''
    ) AS missing_category_labels

FROM mart.fact_order_items;
