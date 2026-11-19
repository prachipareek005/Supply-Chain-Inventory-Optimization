
-- Phase 2: PostgreSQL database architecture
-- Run inside the supply_chain_analytics database

CREATE SCHEMA IF NOT EXISTS raw;
CREATE SCHEMA IF NOT EXISTS clean;
CREATE SCHEMA IF NOT EXISTS mart;
CREATE SCHEMA IF NOT EXISTS qa;


SELECT
    schema_name
FROM information_schema.schemata
WHERE schema_name IN ('raw', 'clean', 'mart', 'qa')
ORDER BY schema_name;

SELECT current_database();

