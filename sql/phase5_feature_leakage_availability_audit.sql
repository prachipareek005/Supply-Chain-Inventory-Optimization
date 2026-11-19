SELECT
    dataset_source,
    COUNT(*) AS total_skus,

    COUNT(*) FILTER (
        WHERE pieces_past_due IS NULL
    ) AS missing_pieces_past_due,

    COUNT(*) FILTER (
        WHERE local_bo_qty IS NULL
    ) AS missing_local_bo_qty,

    COUNT(*) FILTER (
        WHERE potential_issue IS NULL
    ) AS missing_potential_issue,

    COUNT(*) FILTER (
        WHERE deck_risk IS NULL
    ) AS missing_deck_risk,

    COUNT(*) FILTER (
        WHERE oe_constraint IS NULL
    ) AS missing_oe_constraint,

    COUNT(*) FILTER (
        WHERE ppap_risk IS NULL
    ) AS missing_ppap_risk,

    COUNT(*) FILTER (
        WHERE stop_auto_buy IS NULL
    ) AS missing_stop_auto_buy,

    COUNT(*) FILTER (
        WHERE rev_stop IS NULL
    ) AS missing_rev_stop

FROM mart.fact_inventory
GROUP BY dataset_source
ORDER BY dataset_source;