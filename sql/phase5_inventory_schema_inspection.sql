SELECT
    ordinal_position,
    column_name,
    data_type,
    is_nullable
FROM information_schema.columns
WHERE table_schema = 'mart'
  AND table_name = 'fact_inventory'
ORDER BY ordinal_position;