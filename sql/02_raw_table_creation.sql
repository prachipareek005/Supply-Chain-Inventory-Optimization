
-- PHASE 2: RAW TABLE CREATION
-- OLIST DATASETS

-- 1. Orders
CREATE TABLE IF NOT EXISTS raw.olist_orders (
    order_id TEXT,
    customer_id TEXT,
    order_status TEXT,
    order_purchase_timestamp TEXT,
    order_approved_at TEXT,
    order_delivered_carrier_date TEXT,
    order_delivered_customer_date TEXT,
    order_estimated_delivery_date TEXT
);

-- 2. Order Items
CREATE TABLE IF NOT EXISTS raw.olist_order_items (
    order_id TEXT,
    order_item_id TEXT,
    product_id TEXT,
    seller_id TEXT,
    shipping_limit_date TEXT,
    price TEXT,
    freight_value TEXT
);

-- 3. Products
CREATE TABLE IF NOT EXISTS raw.olist_products (
    product_id TEXT,
    product_category_name TEXT,
    product_name_lenght TEXT,
    product_description_lenght TEXT,
    product_photos_qty TEXT,
    product_weight_g TEXT,
    product_length_cm TEXT,
    product_height_cm TEXT,
    product_width_cm TEXT
);

-- 4. Sellers
CREATE TABLE IF NOT EXISTS raw.olist_sellers (
    seller_id TEXT,
    seller_zip_code_prefix TEXT,
    seller_city TEXT,
    seller_state TEXT
);

-- 5. Customers
CREATE TABLE IF NOT EXISTS raw.olist_customers (
    customer_id TEXT,
    customer_unique_id TEXT,
    customer_zip_code_prefix TEXT,
    customer_city TEXT,
    customer_state TEXT
);

-- 6. Payments
CREATE TABLE IF NOT EXISTS raw.olist_order_payments (
    order_id TEXT,
    payment_sequential TEXT,
    payment_type TEXT,
    payment_installments TEXT,
    payment_value TEXT
);

-- 7. Reviews
CREATE TABLE IF NOT EXISTS raw.olist_order_reviews (
    review_id TEXT,
    order_id TEXT,
    review_score TEXT,
    review_comment_title TEXT,
    review_comment_message TEXT,
    review_creation_date TEXT,
    review_answer_timestamp TEXT
);

-- 8. Geolocation
CREATE TABLE IF NOT EXISTS raw.olist_geolocation (
    geolocation_zip_code_prefix TEXT,
    geolocation_lat TEXT,
    geolocation_lng TEXT,
    geolocation_city TEXT,
    geolocation_state TEXT
);

-- 9. Category Translation
CREATE TABLE IF NOT EXISTS raw.product_category_translation (
    product_category_name TEXT,
    product_category_name_english TEXT
);


-- CLU INVENTORY DATASETS

-- 10. CLU Training
CREATE TABLE IF NOT EXISTS raw.clu_train (
    sku TEXT,
    national_inv TEXT,
    lead_time TEXT,
    in_transit_qty TEXT,
    forecast_3_month TEXT,
    forecast_6_month TEXT,
    forecast_9_month TEXT,
    sales_1_month TEXT,
    sales_3_month TEXT,
    sales_6_month TEXT,
    sales_9_month TEXT,
    min_bank TEXT,
    potential_issue TEXT,
    pieces_past_due TEXT,
    perf_6_month_avg TEXT,
    perf_12_month_avg TEXT,
    local_bo_qty TEXT,
    deck_risk TEXT,
    oe_constraint TEXT,
    ppap_risk TEXT,
    stop_auto_buy TEXT,
    rev_stop TEXT,
    went_on_backorder TEXT
);

-- 11. CLU Test
CREATE TABLE IF NOT EXISTS raw.clu_test (
    sku TEXT,
    national_inv TEXT,
    lead_time TEXT,
    in_transit_qty TEXT,
    forecast_3_month TEXT,
    forecast_6_month TEXT,
    forecast_9_month TEXT,
    sales_1_month TEXT,
    sales_3_month TEXT,
    sales_6_month TEXT,
    sales_9_month TEXT,
    min_bank TEXT,
    potential_issue TEXT,
    pieces_past_due TEXT,
    perf_6_month_avg TEXT,
    perf_12_month_avg TEXT,
    local_bo_qty TEXT,
    deck_risk TEXT,
    oe_constraint TEXT,
    ppap_risk TEXT,
    stop_auto_buy TEXT,
    rev_stop TEXT
);


SELECT
    table_name
FROM information_schema.tables
WHERE table_schema = 'raw'
  AND table_type = 'BASE TABLE'
ORDER BY table_name;


SELECT
    table_name,
    COUNT(*) AS column_count
FROM information_schema.columns
WHERE table_schema = 'raw'
GROUP BY table_name
ORDER BY table_name;

SELECT COUNT(*) FROM raw.olist_orders;

SELECT COUNT(*) FROM raw.clu_train;