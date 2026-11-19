SELECT
    COUNT(*) AS total_training_skus,

    COUNT(*) FILTER (
        WHERE national_inv < 0
    ) AS negative_inventory,

    COUNT(*) FILTER (
        WHERE national_inv = 0
    ) AS zero_inventory,

    COUNT(*) FILTER (
        WHERE lead_time = 0
    ) AS zero_lead_time,

    COUNT(*) FILTER (
        WHERE lead_time < 0
    ) AS negative_lead_time,

    COUNT(*) FILTER (
        WHERE perf_6_month_avg < 0
    ) AS negative_perf_6m,

    COUNT(*) FILTER (
        WHERE perf_12_month_avg < 0
    ) AS negative_perf_12m,

    COUNT(*) FILTER (
        WHERE perf_6_month_avg > 1
    ) AS above_one_perf_6m,

    COUNT(*) FILTER (
        WHERE perf_12_month_avg > 1
    ) AS above_one_perf_12m,

    COUNT(*) FILTER (
        WHERE negative_inventory_flag = 1
    ) AS flagged_negative_inventory,

    COUNT(*) FILTER (
        WHERE missing_lead_time_flag = 1
    ) AS flagged_missing_lead_time,

    COUNT(*) FILTER (
        WHERE zero_lead_time_flag = 1
    ) AS flagged_zero_lead_time,

    COUNT(*) FILTER (
        WHERE perf_6m_sentinel_flag = 1
    ) AS flagged_perf_6m_sentinel,

    COUNT(*) FILTER (
        WHERE perf_12m_sentinel_flag = 1
    ) AS flagged_perf_12m_sentinel

FROM mart.fact_inventory
WHERE dataset_source = 'train'
  AND went_on_backorder IS NOT NULL;