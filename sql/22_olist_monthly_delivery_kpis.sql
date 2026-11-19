
-- Phase 2, Step 4
-- Action 4.9: Monthly Delivery Performance

CREATE OR REPLACE VIEW mart.kpi_delivery_by_month AS

SELECT
    DATE_TRUNC('month', order_purchase_timestamp)::DATE
        AS purchase_month,

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

    ROUND(
        100.0 * COUNT(*) FILTER (
            WHERE late_delivery_flag = 1
              AND delivery_days IS NOT NULL
        )
        / NULLIF(
            COUNT(*) FILTER (
                WHERE order_status = 'delivered'
                  AND order_delivered_customer_date IS NOT NULL
                  AND order_estimated_delivery_date IS NOT NULL
                  AND delivery_days IS NOT NULL
            ),
            0
        ),
        2
    ) AS late_delivery_rate_pct,

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
    ) AS avg_days_late,

    COUNT(*) FILTER (
        WHERE missing_delivery_date_flag = 1
    ) AS missing_delivery_dates

FROM mart.fact_orders

GROUP BY DATE_TRUNC('month', order_purchase_timestamp)::DATE;


-- Action 4.9: Verify Monthly Delivery KPIs

SELECT
    COUNT(*) AS total_month_groups,

    SUM(total_orders) AS total_orders,

    SUM(delivered_orders) AS delivered_orders,

    SUM(eligible_deliveries) AS eligible_deliveries,

    SUM(late_deliveries) AS late_deliveries,

    SUM(missing_delivery_dates) AS missing_delivery_dates

FROM mart.kpi_delivery_by_month;


-- Preview monthly delivery trends

SELECT
    purchase_month,
    total_orders,
    eligible_deliveries,
    late_deliveries,
    late_delivery_rate_pct,
    avg_delivery_days

FROM mart.kpi_delivery_by_month

ORDER BY purchase_month;
