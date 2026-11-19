
-- Phase 2, Step 4
-- Action 4.10: Seller Fulfillment Performance

CREATE OR REPLACE VIEW mart.kpi_seller_fulfillment AS

WITH seller_order_totals AS (
    -- One row per seller per order
    SELECT
        seller_id,
        order_id,

        COUNT(*) AS item_count,
        SUM(item_sales_value) AS item_sales,
        SUM(freight_value) AS freight_charges

    FROM mart.fact_order_items

    GROUP BY seller_id, order_id
),

seller_metrics AS (
    SELECT
        soi.seller_id,

        COUNT(*) AS total_seller_orders,

        SUM(soi.item_count) AS total_items,

        SUM(soi.item_sales) AS total_item_sales,

        SUM(soi.freight_charges) AS total_freight,

        COUNT(*) FILTER (
            WHERE o.order_status = 'delivered'
        ) AS delivered_orders,

        COUNT(*) FILTER (
            WHERE o.order_status = 'delivered'
              AND o.order_delivered_customer_date IS NOT NULL
              AND o.order_estimated_delivery_date IS NOT NULL
              AND o.delivery_days IS NOT NULL
        ) AS eligible_deliveries,

        COUNT(*) FILTER (
            WHERE o.late_delivery_flag = 1
              AND o.delivery_days IS NOT NULL
        ) AS late_deliveries,

        ROUND(
            AVG(o.delivery_days) FILTER (
                WHERE o.order_status = 'delivered'
                  AND o.delivery_days IS NOT NULL
                  AND o.order_estimated_delivery_date IS NOT NULL
            ),
            2
        ) AS avg_delivery_days

    FROM seller_order_totals soi

    LEFT JOIN mart.fact_orders o
        ON soi.order_id = o.order_id

    GROUP BY soi.seller_id
)

SELECT
    s.seller_id,
    s.seller_city,
    s.seller_state,

    COALESCE(m.total_seller_orders, 0)
        AS total_seller_orders,

    COALESCE(m.total_items, 0)
        AS total_items,

    COALESCE(m.total_item_sales, 0)
        AS total_item_sales,

    COALESCE(m.total_freight, 0)
        AS total_freight,

    COALESCE(m.delivered_orders, 0)
        AS delivered_orders,

    COALESCE(m.eligible_deliveries, 0)
        AS eligible_deliveries,

    COALESCE(m.late_deliveries, 0)
        AS late_deliveries,

    ROUND(
        100.0 * m.late_deliveries
        / NULLIF(m.eligible_deliveries, 0),
        2
    ) AS late_delivery_rate_pct,

    m.avg_delivery_days

FROM clean.olist_sellers s

LEFT JOIN seller_metrics m
    ON s.seller_id = m.seller_id;


-- Action 4.10: Verify Seller Fulfillment View

SELECT
    COUNT(*) AS total_sellers,

    COUNT(DISTINCT seller_id)
        AS unique_sellers,

    COUNT(*) - COUNT(DISTINCT seller_id)
        AS duplicate_seller_ids,

    COALESCE(SUM(total_items), 0)
        AS total_items,

    ROUND(
        COALESCE(SUM(total_item_sales), 0), 2
    ) AS total_item_sales,

    ROUND(
        COALESCE(SUM(total_freight), 0), 2
    ) AS total_freight,

    COUNT(*) FILTER (
        WHERE total_seller_orders = 0
    ) AS sellers_without_orders

FROM mart.kpi_seller_fulfillment;
