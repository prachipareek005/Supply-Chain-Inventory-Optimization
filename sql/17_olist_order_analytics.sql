
-- Phase 2, Step 4
-- Action 4.3: Create Olist order-level analytics view

CREATE OR REPLACE VIEW mart.fact_orders AS

SELECT
    -- Order and customer identifiers
    o.order_id,
    o.customer_id,
    c.customer_unique_id,

    -- Order information
    o.order_status,
    o.order_purchase_timestamp,
    o.order_approved_at,
    o.order_delivered_carrier_date,
    o.order_delivered_customer_date,
    o.order_estimated_delivery_date,

    -- Date for Power BI relationships
    o.order_purchase_timestamp::DATE
        AS purchase_date,

    -- Customer geography
    c.customer_city,
    c.customer_state,
    c.customer_zip_code_prefix,

    -- Actual delivery time (in days)
    CASE
        WHEN o.order_delivered_customer_date
             >= o.order_purchase_timestamp
        THEN ROUND(
            EXTRACT(EPOCH FROM (
                o.order_delivered_customer_date
                - o.order_purchase_timestamp
            ))::NUMERIC / 86400,
            2
        )
        ELSE NULL
    END AS delivery_days,

    -- Days late compared with estimated delivery date
    CASE
        WHEN o.order_delivered_customer_date IS NOT NULL
         AND o.order_estimated_delivery_date IS NOT NULL
        THEN GREATEST(
            o.order_delivered_customer_date::DATE
            - o.order_estimated_delivery_date::DATE,
            0
        )
        ELSE NULL
    END AS days_late,

    -- Valid actual delivery indicator
    CASE
        WHEN o.order_status = 'delivered'
         AND o.order_delivered_customer_date IS NOT NULL
        THEN 1 ELSE 0
    END AS delivered_order_flag,

    -- Late-delivery indicator
    CASE
        WHEN o.order_status = 'delivered'
         AND o.order_delivered_customer_date::DATE
             > o.order_estimated_delivery_date::DATE
        THEN 1 ELSE 0
    END AS late_delivery_flag,

    -- Missing actual delivery timestamp
    CASE
        WHEN o.order_status = 'delivered'
         AND o.order_delivered_customer_date IS NULL
        THEN 1 ELSE 0
    END AS missing_delivery_date_flag

FROM clean.olist_orders o

LEFT JOIN clean.olist_customers c
    ON o.customer_id = c.customer_id;


-- Action 4.3: Verify order-level analytics view

SELECT
    COUNT(*) AS total_rows,

    COUNT(DISTINCT order_id) AS unique_orders,

    COUNT(*) - COUNT(DISTINCT order_id)
        AS duplicate_order_ids,

    COUNT(*) FILTER (
        WHERE customer_unique_id IS NULL
    ) AS unmatched_customer_records,

    COUNT(*) FILTER (
        WHERE late_delivery_flag = 1
    ) AS late_deliveries,

    COUNT(*) FILTER (
        WHERE missing_delivery_date_flag = 1
    ) AS delivered_orders_missing_dates

FROM mart.fact_orders;
