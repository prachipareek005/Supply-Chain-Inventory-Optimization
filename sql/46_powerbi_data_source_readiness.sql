
-- Phase 2: Power BI Preparation
-- Action 4.33: Data Source Readiness

WITH required_views AS (

    SELECT *
    FROM (
        VALUES
        -- Olist Analytics
        ('Olist', 'fact_orders'),
        ('Olist', 'fact_order_items'),
        ('Olist', 'order_financial_summary'),
        ('Olist', 'kpi_delivery_performance'),
        ('Olist', 'kpi_delivery_by_state'),
        ('Olist', 'kpi_delivery_by_month'),
        ('Olist', 'kpi_seller_fulfillment'),
        ('Olist', 'kpi_seller_delivery_risk'),
        ('Olist', 'kpi_shipping_freight'),
        ('Olist', 'kpi_product_category'),

        -- CLU Inventory Analytics
        ('CLU', 'fact_inventory'),
        ('CLU', 'kpi_inventory_availability'),
        ('CLU', 'inventory_shortage_risk'),
        ('CLU', 'inventory_demand_forecast'),
        ('CLU', 'kpi_inventory_demand_coverage'),
        ('CLU', 'kpi_forecast_vs_sales'),
        ('CLU', 'kpi_backorders_by_shortage_risk'),
        ('CLU', 'kpi_backorders_by_lead_time'),
        ('CLU', 'kpi_backorders_by_forecast_category'),
        ('CLU', 'kpi_backorders_by_supplier_performance'),
        ('CLU', 'kpi_supplier_performance_risk'),
        ('CLU', 'kpi_backorders_by_risk_indicator'),
        ('CLU', 'kpi_risk_indicator_effectiveness'),
        ('CLU', 'backorder_model_features'),
        ('CLU', 'kpi_backorder_feature_quality'),
        ('CLU', 'kpi_backorder_model_readiness')
    ) AS v(dataset_group, view_name)
)

SELECT
    r.dataset_group,
    r.view_name,

    CASE
        WHEN t.table_name IS NOT NULL
        THEN 'PASS'
        ELSE 'MISSING'
    END AS readiness_status

FROM required_views r

LEFT JOIN information_schema.views t
    ON t.table_schema = 'mart'
   AND t.table_name = r.view_name

ORDER BY
    r.dataset_group,
    r.view_name;


-- Action 4.33: Summary of existing mart views

SELECT
    COUNT(*) AS total_mart_views
FROM information_schema.views
WHERE table_schema = 'mart';
