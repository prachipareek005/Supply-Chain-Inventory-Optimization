
-- Phase 2, Step 4
-- Action 4.8: Regional Delivery Performance

CREATE OR REPLACE VIEW mart.kpi_delivery_by_state AS

SELECT
    COALESCE(customer_state, 'UNKNOWN')
        AS customer_state,

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
    ) AS avg_days_late

FROM mart.fact_orders

GROUP BY COALESCE(customer_state, 'UNKNOWN');


-- Action 4.8: Verify regional delivery KPIs

SELECT
    COUNT(*) AS total_state_groups,

    SUM(total_orders) AS total_orders,

    SUM(delivered_orders) AS delivered_orders,

    SUM(eligible_deliveries) AS eligible_deliveries,

    SUM(late_deliveries) AS late_deliveries

FROM mart.kpi_delivery_by_state;


-- Preview states with highest late-delivery rates

SELECT
    customer_state,
    eligible_deliveries,
    late_deliveries,
    late_delivery_rate_pct,
    avg_delivery_days,
    avg_days_late

FROM mart.kpi_delivery_by_state

WHERE eligible_deliveries >= 100

ORDER BY late_delivery_rate_pct DESC

LIMIT 10;
