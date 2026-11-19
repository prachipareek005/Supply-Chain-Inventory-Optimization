SELECT
    COUNT(*) AS total_training_skus,

    COUNT(*) FILTER (
        WHERE national_inv IS NULL
    ) AS missing_national_inv,

    COUNT(*) FILTER (
        WHERE lead_time IS NULL
    ) AS missing_lead_time,

    COUNT(*) FILTER (
        WHERE in_transit_qty IS NULL
    ) AS missing_in_transit_qty,

    COUNT(*) FILTER (
        WHERE min_bank IS NULL
    ) AS missing_min_bank,

    COUNT(*) FILTER (
        WHERE forecast_3_month IS NULL
    ) AS missing_forecast_3m,

    COUNT(*) FILTER (
        WHERE forecast_6_month IS NULL
    ) AS missing_forecast_6m,

    COUNT(*) FILTER (
        WHERE forecast_9_month IS NULL
    ) AS missing_forecast_9m,

    COUNT(*) FILTER (
        WHERE sales_1_month IS NULL
    ) AS missing_sales_1m,

    COUNT(*) FILTER (
        WHERE sales_3_month IS NULL
    ) AS missing_sales_3m,

    COUNT(*) FILTER (
        WHERE sales_6_month IS NULL
    ) AS missing_sales_6m,

    COUNT(*) FILTER (
        WHERE sales_9_month IS NULL
    ) AS missing_sales_9m,

    COUNT(*) FILTER (
        WHERE perf_6_month_avg IS NULL
    ) AS missing_perf_6m,

    COUNT(*) FILTER (
        WHERE perf_12_month_avg IS NULL
    ) AS missing_perf_12m

FROM mart.fact_inventory
WHERE dataset_source = 'train'
  AND went_on_backorder IS NOT NULL;