
-- Phase 2, Step 4
-- Action 4.11: Seller Delivery Risk Analysis

CREATE OR REPLACE VIEW mart.kpi_seller_delivery_risk AS

WITH benchmark AS (
    SELECT
        late_delivery_rate_pct AS overall_late_rate
    FROM mart.kpi_delivery_performance
)

SELECT
    s.seller_id,
    s.seller_city,
    s.seller_state,

    s.total_seller_orders,
    s.eligible_deliveries,
    s.late_deliveries,
    s.late_delivery_rate_pct,
    s.avg_delivery_days,

    b.overall_late_rate,

    CASE
        WHEN s.eligible_deliveries = 0
            THEN 'No Eligible Deliveries'

        WHEN s.eligible_deliveries < 30
            THEN 'Insufficient Volume'

        WHEN s.late_delivery_rate_pct >=
             b.overall_late_rate * 2
            THEN 'High Delay Rate'

        WHEN s.late_delivery_rate_pct >
             b.overall_late_rate
            THEN 'Above Benchmark'

        ELSE 'At or Below Benchmark'
    END AS delivery_risk_category

FROM mart.kpi_seller_fulfillment s

CROSS JOIN benchmark b;


-- Action 4.11: Verify Seller Risk Categories

SELECT
    delivery_risk_category,

    COUNT(*) AS seller_count,

    SUM(eligible_deliveries)
        AS eligible_deliveries,

    SUM(late_deliveries)
        AS late_deliveries

FROM mart.kpi_seller_delivery_risk

GROUP BY delivery_risk_category

ORDER BY delivery_risk_category;


-- Preview sellers associated with high delivery-delay rates

SELECT
    seller_id,
    seller_state,
    eligible_deliveries,
    late_deliveries,
    late_delivery_rate_pct,
    overall_late_rate,
    delivery_risk_category

FROM mart.kpi_seller_delivery_risk

WHERE delivery_risk_category = 'High Delay Rate'

ORDER BY
    late_delivery_rate_pct DESC,
    eligible_deliveries DESC

LIMIT 10;
