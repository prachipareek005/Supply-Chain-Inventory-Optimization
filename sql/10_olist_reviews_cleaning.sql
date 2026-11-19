
-- Action 3.24: Validate Olist Reviews data

SELECT
    COUNT(*) AS total_reviews,

    COUNT(*) FILTER (
        WHERE review_comment_title IS NULL
           OR TRIM(review_comment_title) = ''
    ) AS missing_titles,

    COUNT(*) FILTER (
        WHERE review_comment_message IS NULL
           OR TRIM(review_comment_message) = ''
    ) AS missing_messages,

    COUNT(*) FILTER (
        WHERE review_score IS NULL
           OR TRIM(review_score) = ''
           OR NOT pg_input_is_valid(review_score, 'integer')
    ) AS invalid_score_types,

    COUNT(*) FILTER (
        WHERE review_creation_date IS NULL
           OR TRIM(review_creation_date) = ''
           OR NOT pg_input_is_valid(
               review_creation_date,
               'timestamp without time zone'
           )
    ) AS invalid_creation_dates,

    COUNT(*) FILTER (
        WHERE review_answer_timestamp IS NULL
           OR TRIM(review_answer_timestamp) = ''
           OR NOT pg_input_is_valid(
               review_answer_timestamp,
               'timestamp without time zone'
           )
    ) AS invalid_answer_dates

FROM raw.olist_order_reviews;


-- Action 3.25: Create cleaned Olist Reviews table

CREATE TABLE IF NOT EXISTS clean.olist_order_reviews (
    review_record_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    review_id TEXT,
    order_id TEXT,
    review_score INTEGER,
    review_comment_title TEXT,
    review_comment_message TEXT,
    review_creation_date TIMESTAMP,
    review_answer_timestamp TIMESTAMP,
    missing_title_flag INTEGER,
    missing_message_flag INTEGER
);

INSERT INTO clean.olist_order_reviews (
    review_id,
    order_id,
    review_score,
    review_comment_title,
    review_comment_message,
    review_creation_date,
    review_answer_timestamp,
    missing_title_flag,
    missing_message_flag
)
SELECT
    TRIM(review_id),
    TRIM(order_id),
    NULLIF(TRIM(review_score), '')::INTEGER,
    NULLIF(TRIM(review_comment_title), ''),
    NULLIF(TRIM(review_comment_message), ''),
    NULLIF(TRIM(review_creation_date), '')::TIMESTAMP,
    NULLIF(TRIM(review_answer_timestamp), '')::TIMESTAMP,

    CASE
        WHEN NULLIF(TRIM(review_comment_title), '') IS NULL
        THEN 1 ELSE 0
    END,

    CASE
        WHEN NULLIF(TRIM(review_comment_message), '') IS NULL
        THEN 1 ELSE 0
    END

FROM raw.olist_order_reviews;

TRUNCATE TABLE clean.olist_order_reviews
RESTART IDENTITY;

-- Verify cleaned Olist Reviews

SELECT
    COUNT(*) AS total_reviews,

    COUNT(DISTINCT review_record_id)
        AS unique_record_ids,

    SUM(missing_title_flag)
        AS missing_titles,

    SUM(missing_message_flag)
        AS missing_messages

FROM clean.olist_order_reviews;

-- Action 3.26: Investigate repeated review IDs

WITH review_counts AS (
    SELECT
        review_id,
        COUNT(*) AS record_count,
        COUNT(DISTINCT order_id) AS distinct_order_count
    FROM clean.olist_order_reviews
    GROUP BY review_id
)
SELECT
    (SELECT COUNT(*)
     FROM clean.olist_order_reviews) AS total_reviews,

    COUNT(*) AS unique_review_ids,

    SUM(record_count - 1) AS extra_id_occurrences,

    COUNT(*) FILTER (
        WHERE record_count > 1
    ) AS repeated_review_ids,

    COUNT(*) FILTER (
        WHERE distinct_order_count > 1
    ) AS ids_linked_to_multiple_orders

FROM review_counts;


-- Action 3.27: Optimized Reviews integrity check

SELECT
    COUNT(*) AS total_reviews,

    COUNT(*) FILTER (
        WHERE r.review_score IS NULL
           OR r.review_score NOT BETWEEN 1 AND 5
    ) AS invalid_review_scores,

    COUNT(*) FILTER (
        WHERE r.review_answer_timestamp < r.review_creation_date
    ) AS answers_before_creation,

    COUNT(*) FILTER (
        WHERE o.order_id IS NULL
    ) AS unmatched_order_references

FROM clean.olist_order_reviews r
LEFT JOIN clean.olist_orders o
    ON r.order_id = o.order_id;



-- Action 3.28: Final Reviews integrity check
-- Compare source and cleaned records

WITH source_counts AS (
    SELECT
        review_id,
        order_id,
        review_score::INTEGER AS review_score,
        NULLIF(TRIM(review_comment_title), '') AS review_comment_title,
        NULLIF(TRIM(review_comment_message), '') AS review_comment_message,
        review_creation_date::TIMESTAMP AS review_creation_date,
        review_answer_timestamp::TIMESTAMP AS review_answer_timestamp,
        COUNT(*) AS record_count
    FROM raw.olist_order_reviews
    GROUP BY 1, 2, 3, 4, 5, 6, 7
),
clean_counts AS (
    SELECT
        review_id,
        order_id,
        review_score,
        review_comment_title,
        review_comment_message,
        review_creation_date,
        review_answer_timestamp,
        COUNT(*) AS record_count
    FROM clean.olist_order_reviews
    GROUP BY 1, 2, 3, 4, 5, 6, 7
),
differences AS (
    SELECT * FROM source_counts
    EXCEPT ALL
    SELECT * FROM clean_counts

    UNION ALL

    SELECT * FROM clean_counts
    EXCEPT ALL
    SELECT * FROM source_counts
)
SELECT
    (SELECT COUNT(*) FROM raw.olist_order_reviews)
        AS raw_rows,

    (SELECT COUNT(*) FROM clean.olist_order_reviews)
        AS clean_rows,

    (SELECT COUNT(*) FROM differences)
        AS mismatched_record_groups;
