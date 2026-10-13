-- Data QA checklist · Stage 1 · Standard v1
-- Scope: mql_leads, closed_deals, orders, order_items, sellers (olist001.raw)
-- Read-only. Every block outputs the same 5 columns: check_name, table_name, metric, value, note
-- Pass criteria: data_prep/2_data_qa/checklist.md
-- Run: bq query --project_id=olist001 --use_legacy_sql=false --format=csv --max_rows=10000 < this_file.sql

WITH params AS (
  SELECT DATE '2018-08-30' AS order_cutoff  -- order-data cutoff (processing assumption; see docs/cleaning_log.md)
),

results AS (

-- ============================================================
-- rows_completion: row count per table vs. published Kaggle counts
-- ============================================================
SELECT 'rows_completion' AS check_name, 'mql_leads' AS table_name, 'row_count' AS metric,
       CAST(COUNT(*) AS STRING) AS value, 'expected 8000' AS note FROM `olist001.raw.mql_leads`
UNION ALL SELECT 'rows_completion', 'closed_deals', 'row_count', CAST(COUNT(*) AS STRING), 'expected 842' FROM `olist001.raw.closed_deals`
UNION ALL SELECT 'rows_completion', 'orders', 'row_count', CAST(COUNT(*) AS STRING), 'expected 99441' FROM `olist001.raw.orders`
UNION ALL SELECT 'rows_completion', 'order_items', 'row_count', CAST(COUNT(*) AS STRING), 'expected 112650' FROM `olist001.raw.order_items`
UNION ALL SELECT 'rows_completion', 'sellers', 'row_count', CAST(COUNT(*) AS STRING), 'expected 3095' FROM `olist001.raw.sellers`

-- ============================================================
-- data_type: actual type of every column (as autodetected at load)
-- ============================================================
UNION ALL
SELECT 'data_type', table_name, column_name, data_type, ''
FROM `olist001.raw.INFORMATION_SCHEMA.COLUMNS`
WHERE table_name IN ('mql_leads', 'closed_deals', 'orders', 'order_items', 'sellers')

-- Date-like columns still stored as STRING (these would need cast-failure counts in a transform step)
UNION ALL
SELECT 'data_type', 'all_stage1', 'string_date_columns', CAST(COUNT(*) AS STRING),
       'date-like columns stored as STRING'
FROM `olist001.raw.INFORMATION_SCHEMA.COLUMNS`
WHERE table_name IN ('mql_leads', 'closed_deals', 'orders', 'order_items', 'sellers')
  AND REGEXP_CONTAINS(column_name, r'(_date|_at|_timestamp)$')
  AND data_type = 'STRING'

-- ============================================================
-- distinct_primary_key: duplicate keys = row count - distinct key count
-- ============================================================
UNION ALL SELECT 'distinct_primary_key', 'orders', 'dup_order_id', CAST(COUNT(*) - COUNT(DISTINCT order_id) AS STRING), '' FROM `olist001.raw.orders`
UNION ALL SELECT 'distinct_primary_key', 'sellers', 'dup_seller_id', CAST(COUNT(*) - COUNT(DISTINCT seller_id) AS STRING), '' FROM `olist001.raw.sellers`
UNION ALL SELECT 'distinct_primary_key', 'mql_leads', 'dup_mql_id', CAST(COUNT(*) - COUNT(DISTINCT mql_id) AS STRING), '' FROM `olist001.raw.mql_leads`
UNION ALL SELECT 'distinct_primary_key', 'closed_deals', 'dup_mql_id', CAST(COUNT(*) - COUNT(DISTINCT mql_id) AS STRING), '' FROM `olist001.raw.closed_deals`
UNION ALL SELECT 'distinct_primary_key', 'order_items', 'dup_order_item_key',
       CAST(COUNT(*) - COUNT(DISTINCT CONCAT(order_id, '-', CAST(order_item_id AS STRING))) AS STRING),
       'key = order_id + order_item_id' FROM `olist001.raw.order_items`

-- ============================================================
-- null_check: NULL count for every column of every table (columns expanded automatically via JSON)
-- ============================================================
UNION ALL
SELECT 'null_check', tbl, CONCAT('null_', col), CAST(COUNTIF(is_null) AS STRING),
       FORMAT('%.2f%% of %d rows', 100 * COUNTIF(is_null) / COUNT(*), COUNT(*))
FROM (
  SELECT 'mql_leads' AS tbl, col, JSON_TYPE(j[col]) = 'null' AS is_null
  FROM (SELECT TO_JSON(t) AS j FROM `olist001.raw.mql_leads` t), UNNEST(JSON_KEYS(j)) AS col
  UNION ALL
  SELECT 'closed_deals', col, JSON_TYPE(j[col]) = 'null'
  FROM (SELECT TO_JSON(t) AS j FROM `olist001.raw.closed_deals` t), UNNEST(JSON_KEYS(j)) AS col
  UNION ALL
  SELECT 'orders', col, JSON_TYPE(j[col]) = 'null'
  FROM (SELECT TO_JSON(t) AS j FROM `olist001.raw.orders` t), UNNEST(JSON_KEYS(j)) AS col
  UNION ALL
  SELECT 'order_items', col, JSON_TYPE(j[col]) = 'null'
  FROM (SELECT TO_JSON(t) AS j FROM `olist001.raw.order_items` t), UNNEST(JSON_KEYS(j)) AS col
  UNION ALL
  SELECT 'sellers', col, JSON_TYPE(j[col]) = 'null'
  FROM (SELECT TO_JSON(t) AS j FROM `olist001.raw.sellers` t), UNNEST(JSON_KEYS(j)) AS col
)
GROUP BY tbl, col

-- ============================================================
-- date_logic: event order + date ranges
-- ============================================================
UNION ALL
SELECT 'date_logic', 'orders', 'delivered_before_purchase',
       CAST(COUNTIF(order_delivered_customer_date < order_purchase_timestamp) AS STRING), ''
FROM `olist001.raw.orders`
UNION ALL SELECT 'date_logic', 'orders', 'min_purchase_ts', CAST(MIN(order_purchase_timestamp) AS STRING), 'expected ~2016-09' FROM `olist001.raw.orders`
UNION ALL SELECT 'date_logic', 'orders', 'max_purchase_ts', CAST(MAX(order_purchase_timestamp) AS STRING), 'expected ~2018-10' FROM `olist001.raw.orders`
UNION ALL
SELECT 'date_logic', 'closed_deals', 'won_before_first_contact',
       CAST(COUNTIF(DATE(c.won_date) < m.first_contact_date) AS STRING), 'joined to mql_leads on mql_id'
FROM `olist001.raw.closed_deals` c
JOIN `olist001.raw.mql_leads` m USING (mql_id)
UNION ALL SELECT 'date_logic', 'mql_leads', 'min_first_contact_date', CAST(MIN(first_contact_date) AS STRING), 'expected ~2017-06' FROM `olist001.raw.mql_leads`
UNION ALL SELECT 'date_logic', 'mql_leads', 'max_first_contact_date', CAST(MAX(first_contact_date) AS STRING), 'expected ~2018-05' FROM `olist001.raw.mql_leads`
UNION ALL SELECT 'date_logic', 'closed_deals', 'min_won_date', CAST(MIN(won_date) AS STRING), 'should not precede min_first_contact_date' FROM `olist001.raw.closed_deals`
UNION ALL SELECT 'date_logic', 'closed_deals', 'max_won_date', CAST(MAX(won_date) AS STRING), '' FROM `olist001.raw.closed_deals`

-- ============================================================
-- value_range: are amounts plausible?
-- ============================================================
UNION ALL SELECT 'value_range', 'order_items', 'price_le_0', CAST(COUNTIF(price <= 0) AS STRING), '' FROM `olist001.raw.order_items`
UNION ALL SELECT 'value_range', 'order_items', 'freight_lt_0', CAST(COUNTIF(freight_value < 0) AS STRING), '' FROM `olist001.raw.order_items`
UNION ALL SELECT 'value_range', 'order_items', 'price_p50', CAST(APPROX_QUANTILES(price, 100)[OFFSET(50)] AS STRING), '' FROM `olist001.raw.order_items`
UNION ALL SELECT 'value_range', 'order_items', 'price_p99', CAST(APPROX_QUANTILES(price, 100)[OFFSET(99)] AS STRING), '' FROM `olist001.raw.order_items`
UNION ALL SELECT 'value_range', 'order_items', 'price_max', CAST(MAX(price) AS STRING), '' FROM `olist001.raw.order_items`
UNION ALL SELECT 'value_range', 'order_items', 'freight_p99', CAST(APPROX_QUANTILES(freight_value, 100)[OFFSET(99)] AS STRING), '' FROM `olist001.raw.order_items`
UNION ALL SELECT 'value_range', 'order_items', 'freight_max', CAST(MAX(freight_value) AS STRING), '' FROM `olist001.raw.order_items`

-- ============================================================
-- category_values: order_status distribution; earliest purchase date of in-progress orders
-- ============================================================
UNION ALL
SELECT 'category_values', 'orders', CONCAT('status_', IFNULL(order_status, 'NULL')), CAST(COUNT(*) AS STRING),
       FORMAT('min_purchase=%s', CAST(DATE(MIN(order_purchase_timestamp)) AS STRING))
FROM `olist001.raw.orders`
GROUP BY order_status
UNION ALL
SELECT 'category_values', 'orders', 'stuck_intermediate_before_cutoff_minus_30d',
       CAST(COUNTIF(DATE(order_purchase_timestamp) < DATE_SUB((SELECT order_cutoff FROM params), INTERVAL 30 DAY)) AS STRING),
       'status in shipped/processing/approved/invoiced/created, purchased >30d before cutoff'
FROM `olist001.raw.orders`
WHERE order_status IN ('shipped', 'processing', 'approved', 'invoiced', 'created')

-- ============================================================
-- duplicate_rows: fully duplicated rows
-- ============================================================
UNION ALL SELECT 'duplicate_rows', 'mql_leads', 'full_row_dups', CAST(COUNT(*) - COUNT(DISTINCT TO_JSON_STRING(t)) AS STRING), '' FROM `olist001.raw.mql_leads` t
UNION ALL SELECT 'duplicate_rows', 'closed_deals', 'full_row_dups', CAST(COUNT(*) - COUNT(DISTINCT TO_JSON_STRING(t)) AS STRING), '' FROM `olist001.raw.closed_deals` t
UNION ALL SELECT 'duplicate_rows', 'orders', 'full_row_dups', CAST(COUNT(*) - COUNT(DISTINCT TO_JSON_STRING(t)) AS STRING), '' FROM `olist001.raw.orders` t
UNION ALL SELECT 'duplicate_rows', 'order_items', 'full_row_dups', CAST(COUNT(*) - COUNT(DISTINCT TO_JSON_STRING(t)) AS STRING), '' FROM `olist001.raw.order_items` t
UNION ALL SELECT 'duplicate_rows', 'sellers', 'full_row_dups', CAST(COUNT(*) - COUNT(DISTINCT TO_JSON_STRING(t)) AS STRING), '' FROM `olist001.raw.sellers` t

-- ============================================================
-- referential_integrity: do the tables join without orphans?
-- ============================================================
UNION ALL
SELECT 'referential_integrity', 'order_items', 'orphan_order_items', CAST(COUNTIF(o.order_id IS NULL) AS STRING),
       'order_items rows whose order_id is not in orders'
FROM `olist001.raw.order_items` i LEFT JOIN `olist001.raw.orders` o USING (order_id)
UNION ALL
SELECT 'referential_integrity', 'order_items', 'orphan_seller_ids', CAST(COUNTIF(s.seller_id IS NULL) AS STRING),
       'order_items rows whose seller_id is not in sellers'
FROM `olist001.raw.order_items` i LEFT JOIN `olist001.raw.sellers` s USING (seller_id)
UNION ALL
SELECT 'referential_integrity', 'closed_deals', 'orphan_closed_deals', CAST(COUNTIF(m.mql_id IS NULL) AS STRING),
       'closed_deals rows whose mql_id is not in mql_leads'
FROM `olist001.raw.closed_deals` c LEFT JOIN `olist001.raw.mql_leads` m USING (mql_id)

-- ============================================================
-- observation_window: can signed sellers be linked to orders; how many have a full 90-day window
-- ============================================================
UNION ALL
SELECT 'observation_window', 'closed_deals', 'won_sellers', CAST(COUNT(DISTINCT seller_id) AS STRING), 'distinct seller_id in closed_deals'
FROM `olist001.raw.closed_deals`
UNION ALL
SELECT 'observation_window', 'closed_deals', 'match_rate',
       FORMAT('%.4f', COUNT(DISTINCT IF(i.seller_id IS NOT NULL, c.seller_id, NULL)) / COUNT(DISTINCT c.seller_id)),
       FORMAT('%d of %d won sellers have >=1 row in order_items',
              COUNT(DISTINCT IF(i.seller_id IS NOT NULL, c.seller_id, NULL)), COUNT(DISTINCT c.seller_id))
FROM `olist001.raw.closed_deals` c
LEFT JOIN (SELECT DISTINCT seller_id FROM `olist001.raw.order_items`) i USING (seller_id)
UNION ALL
SELECT 'observation_window', 'closed_deals', 'sellers_with_90d_window',
       CAST(COUNT(DISTINCT seller_id) AS STRING),
       FORMAT('won_date <= %s (cutoff - 90d)', CAST(DATE_SUB((SELECT order_cutoff FROM params), INTERVAL 90 DAY) AS STRING))
FROM `olist001.raw.closed_deals`
WHERE DATE(won_date) <= DATE_SUB((SELECT order_cutoff FROM params), INTERVAL 90 DAY)
UNION ALL
SELECT 'observation_window', 'closed_deals', 'matched_sellers_with_90d_window',
       CAST(COUNT(DISTINCT c.seller_id) AS STRING), 'full 90d window AND >=1 row in order_items'
FROM `olist001.raw.closed_deals` c
JOIN (SELECT DISTINCT seller_id FROM `olist001.raw.order_items`) i USING (seller_id)
WHERE DATE(c.won_date) <= DATE_SUB((SELECT order_cutoff FROM params), INTERVAL 90 DAY)
UNION ALL
SELECT 'observation_window', 'orders', 'orders_after_cutoff',
       CAST(COUNTIF(DATE(order_purchase_timestamp) > (SELECT order_cutoff FROM params)) AS STRING),
       FORMAT('purchase date > %s', CAST((SELECT order_cutoff FROM params) AS STRING))
FROM `olist001.raw.orders`
)

SELECT check_name, table_name, metric, value, note
FROM results
ORDER BY
  CASE check_name
    WHEN 'rows_completion' THEN 1 WHEN 'data_type' THEN 2 WHEN 'distinct_primary_key' THEN 3
    WHEN 'null_check' THEN 4 WHEN 'date_logic' THEN 5 WHEN 'value_range' THEN 6
    WHEN 'category_values' THEN 7 WHEN 'duplicate_rows' THEN 8 WHEN 'referential_integrity' THEN 9
    WHEN 'observation_window' THEN 10 END,
  table_name, metric;
