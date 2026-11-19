SELECT
    sku,
    dataset_source,
    went_on_backorder,

    -- Inventory
    national_inv,
    in_transit_qty,
    min_bank,

    -- Forecast demand
    forecast_3_month,
    forecast_6_month,
    forecast_9_month,

    -- Historical demand
    sales_1_month,
    sales_3_month,
    sales_6_month,
    sales_9_month,

    -- Replenishment
    lead_time,

    -- Supplier performance
    perf_6_month_avg,
    perf_12_month_avg,

    -- Data-quality indicators
    negative_inventory_flag,
    missing_lead_time_flag,
    zero_lead_time_flag,
    perf_6m_sentinel_flag,
    perf_12m_sentinel_flag

FROM mart.fact_inventory
ORDER BY dataset_source, sku;