
-- Phase 2, Step 4
-- Action 4.7: Olist Delivery Performance KPIs

CREATE OR REPLACE VIEW mart.kpi_delivery_performance AS

WITH delivery_metrics AS (
    SELECT
        COUNT(*) AS total_orders,

        COUNT(*) FILTER (
            WHERE order_status = 'delivered'
        ) AS delivered_orders,

        COUNT(*) FILTER (
            WHERE order_status = 'delivered'
              AND order_delivered_customer_date IS NOT NULL
              AND order_estimated_delivery_date IS NOT NULL
              AND delivery_days IS NOT NULL
        ) AS eligible_deliveries,

        COUNT(*) FILTER (
            WHERE late_delivery_flag = 1
              AND delivery_days IS NOT NULL
        ) AS late_deliveries,

        COUNT(*) FILTER (
            WHERE missing_delivery_date_flag = 1
        ) AS missing_delivery_dates,

        ROUND(
            AVG(delivery_days) FILTER (
                WHERE order_status = 'delivered'
                  AND delivery_days IS NOT NULL
                  AND order_estimated_delivery_date IS NOT NULL
            ),
            2
        ) AS avg_delivery_days,

        ROUND(
            AVG(days_late) FILTER (
                WHERE late_delivery_flag = 1
                  AND delivery_days IS NOT NULL
            ),
            2
        ) AS avg_days_late

    FROM mart.fact_orders
)

SELECT
    total_orders,
    delivered_orders,
    eligible_deliveries,
    late_deliveries,

    ROUND(
        100.0 * late_deliveries
        / NULLIF(eligible_deliveries, 0),
        2
    ) AS late_delivery_rate_pct,

    avg_delivery_days,
    avg_days_late,
    missing_delivery_dates

FROM delivery_metrics;


-- Action 4.7: Verify Delivery Performance KPIs

SELECT *
FROM mart.kpi_delivery_performance;
