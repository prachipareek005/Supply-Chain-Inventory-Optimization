
-- Action 3.9: Validate Olist Order Items data types

SELECT
    COUNT(*) AS total_items,

    COUNT(*) FILTER (
        WHERE NOT pg_input_is_valid(
            order_item_id, 'integer'
        )
    ) AS invalid_item_ids,

    COUNT(*) FILTER (
        WHERE NOT pg_input_is_valid(
            price, 'numeric'
        )
    ) AS invalid_prices,

    COUNT(*) FILTER (
        WHERE NOT pg_input_is_valid(
            freight_value, 'numeric'
        )
    ) AS invalid_freight_values,

    COUNT(*) FILTER (
        WHERE NOT pg_input_is_valid(
            shipping_limit_date,
            'timestamp without time zone'
        )
    ) AS invalid_shipping_dates

FROM raw.olist_order_items;


-- Action 3.10: Create cleaned Order Items table

CREATE TABLE IF NOT EXISTS clean.olist_order_items AS
SELECT
    order_id,
    order_item_id::INTEGER AS order_item_id,
    product_id,
    seller_id,

    NULLIF(TRIM(shipping_limit_date), '')::TIMESTAMP
        AS shipping_limit_date,

    NULLIF(TRIM(price), '')::NUMERIC(14,2)
        AS price,

    NULLIF(TRIM(freight_value), '')::NUMERIC(14,2)
        AS freight_value,

    CASE
        WHEN freight_value::NUMERIC = 0
        THEN 1 ELSE 0
    END AS zero_freight_flag,

    CASE
        WHEN price::NUMERIC < 0
        THEN 1 ELSE 0
    END AS negative_price_flag,

    CASE
        WHEN freight_value::NUMERIC < 0
        THEN 1 ELSE 0
    END AS negative_freight_flag

FROM raw.olist_order_items;


-- Verify cleaned Order Items

SELECT
    COUNT(*) AS total_items,
    SUM(zero_freight_flag) AS zero_freight,
    SUM(negative_price_flag) AS negative_prices,
    SUM(negative_freight_flag) AS negative_freight
FROM clean.olist_order_items;


-- Action 3.11: Verify cleaned Order Items integrity

SELECT
    (SELECT COUNT(*)
     FROM raw.olist_order_items) AS raw_rows,

    (SELECT COUNT(*)
     FROM clean.olist_order_items) AS clean_rows,

    (SELECT COUNT(*)
     FROM clean.olist_order_items)
    -
    (SELECT COUNT(*)
     FROM raw.olist_order_items) AS row_difference,

    (SELECT COUNT(*)
     FROM (
         SELECT order_id, order_item_id
         FROM clean.olist_order_items
         GROUP BY order_id, order_item_id
         HAVING COUNT(*) > 1
     ) duplicates) AS duplicate_item_keys,

    (SELECT COUNT(*)
     FROM clean.olist_order_items i
     WHERE NOT EXISTS (
         SELECT 1
         FROM clean.olist_orders o
         WHERE o.order_id = i.order_id
     )) AS unmatched_order_references;
