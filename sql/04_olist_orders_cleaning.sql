SELECT
    order_id,
    order_purchase_timestamp,
    order_purchase_timestamp::TIMESTAMP AS converted_purchase_date
FROM raw.olist_orders
LIMIT 10;


-- Action 3.2: Validate all purchase timestamps

SELECT
    COUNT(*) AS total_orders,

    COUNT(*) FILTER (
        WHERE order_purchase_timestamp IS NULL
           OR TRIM(order_purchase_timestamp) = ''
    ) AS missing_timestamps,

    COUNT(*) FILTER (
        WHERE order_purchase_timestamp IS NOT NULL
          AND TRIM(order_purchase_timestamp) <> ''
          AND NOT pg_input_is_valid(
              order_purchase_timestamp,
              'timestamp without time zone'
          )
    ) AS invalid_timestamps

FROM raw.olist_orders;


-- Action 3.3: Validate remaining Orders timestamps

WITH timestamp_values AS (
    SELECT
        v.field_name,
        v.field_value
    FROM raw.olist_orders o
    CROSS JOIN LATERAL (
        VALUES
            ('order_approved_at', o.order_approved_at),
            ('order_delivered_carrier_date', o.order_delivered_carrier_date),
            ('order_delivered_customer_date', o.order_delivered_customer_date),
            ('order_estimated_delivery_date', o.order_estimated_delivery_date)
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
              'timestamp without time zone'
          )
    ) AS invalid_values
FROM timestamp_values
GROUP BY field_name
ORDER BY field_name;


-- Action 3.4: Create cleaned Olist Orders table

CREATE TABLE IF NOT EXISTS clean.olist_orders AS
SELECT
    order_id,
    customer_id,
    order_status,

    NULLIF(TRIM(order_purchase_timestamp), '')::TIMESTAMP
        AS order_purchase_timestamp,

    NULLIF(TRIM(order_approved_at), '')::TIMESTAMP
        AS order_approved_at,

    NULLIF(TRIM(order_delivered_carrier_date), '')::TIMESTAMP
        AS order_delivered_carrier_date,

    NULLIF(TRIM(order_delivered_customer_date), '')::TIMESTAMP
        AS order_delivered_customer_date,

    NULLIF(TRIM(order_estimated_delivery_date), '')::TIMESTAMP
        AS order_estimated_delivery_date,

    CASE
        WHEN NULLIF(TRIM(order_delivered_customer_date), '')::TIMESTAMP
             <
             NULLIF(TRIM(order_purchase_timestamp), '')::TIMESTAMP
        THEN 1 ELSE 0
    END AS delivery_before_purchase_flag,

    CASE
        WHEN NULLIF(TRIM(order_delivered_customer_date), '')::TIMESTAMP
             <
             NULLIF(TRIM(order_delivered_carrier_date), '')::TIMESTAMP
        THEN 1 ELSE 0
    END AS delivery_before_carrier_flag

FROM raw.olist_orders;


SELECT
    COUNT(*) AS total_orders,
    SUM(delivery_before_purchase_flag) AS before_purchase,
    SUM(delivery_before_carrier_flag) AS before_carrier
FROM clean.olist_orders;


-- Action 3.5: Validate late deliveries

SELECT
    COUNT(*) AS valid_delivered_orders,

    COUNT(*) FILTER (
        WHERE order_delivered_customer_date::DATE
              > order_estimated_delivery_date::DATE
    ) AS late_delivered_orders,

    ROUND(
        COUNT(*) FILTER (
            WHERE order_delivered_customer_date::DATE
                  > order_estimated_delivery_date::DATE
        ) * 100.0 / NULLIF(COUNT(*), 0),
        2
    ) AS late_delivery_rate_pct

FROM clean.olist_orders

WHERE order_status = 'delivered'
  AND order_delivered_customer_date IS NOT NULL
  AND order_estimated_delivery_date IS NOT NULL;


-- Action 3.6: Validate missing delivery dates

SELECT
    COUNT(*) AS total_orders,

    COUNT(*) FILTER (
        WHERE order_delivered_customer_date IS NULL
    ) AS missing_delivery_dates,

    COUNT(*) FILTER (
        WHERE order_status = 'delivered'
          AND order_delivered_customer_date IS NULL
    ) AS delivered_without_date,

    COUNT(*) FILTER (
        WHERE order_status = 'delivered'
          AND order_delivered_customer_date IS NOT NULL
    ) AS delivered_with_date

FROM clean.olist_orders;


-- Action 3.7: Create delivery quality flags

CREATE OR REPLACE VIEW clean.olist_orders_delivery AS
SELECT
    o.*,

    CASE
        WHEN order_status = 'delivered'
         AND order_delivered_customer_date IS NULL
        THEN 1 ELSE 0
    END AS missing_delivery_flag,

    CASE
        WHEN order_status = 'delivered'
         AND order_delivered_customer_date IS NOT NULL
         AND order_estimated_delivery_date IS NOT NULL
        THEN 1 ELSE 0
    END AS valid_delivery_flag,

    CASE
        WHEN order_status = 'delivered'
         AND order_delivered_customer_date IS NOT NULL
         AND order_estimated_delivery_date IS NOT NULL
         AND order_delivered_customer_date::DATE
             > order_estimated_delivery_date::DATE
        THEN 1 ELSE 0
    END AS late_delivery_flag

FROM clean.olist_orders o;


SELECT
    COUNT(*) AS total_orders,
    SUM(missing_delivery_flag) AS missing_delivery,
    SUM(valid_delivery_flag) AS valid_deliveries,
    SUM(late_delivery_flag) AS late_deliveries
FROM clean.olist_orders_delivery;


-- Action 3.8: Final Olist Orders integrity check

SELECT
    (SELECT COUNT(*)
     FROM raw.olist_orders) AS raw_rows,

    (SELECT COUNT(*)
     FROM clean.olist_orders) AS clean_rows,

    (SELECT COUNT(*)
     FROM clean.olist_orders)
    -
    (SELECT COUNT(*)
     FROM raw.olist_orders) AS row_difference,

    (SELECT COUNT(*) - COUNT(DISTINCT order_id)
     FROM clean.olist_orders) AS duplicate_order_ids,

    (SELECT COUNT(*)
     FROM clean.olist_orders c
     WHERE NOT EXISTS (
         SELECT 1
         FROM raw.olist_orders r
         WHERE r.order_id = c.order_id
     )) AS unmatched_clean_order_ids;
