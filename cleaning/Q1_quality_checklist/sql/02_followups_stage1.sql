-- Q1 追查查询 · 阶段 1
-- 01_quality_checklist.sql 跑完后，对需要进一步判断的结果做追查。不改数据。
-- 输出格式与 01 相同：check_name, table_name, metric, value, note

WITH params AS (
  SELECT DATE '2018-08-30' AS order_cutoff
),

results AS (

-- null_check：状态是 delivered 但没有送达日期的订单（计划里点名要看）
SELECT 'null_check' AS check_name, 'orders' AS table_name, 'delivered_but_null_delivered_date' AS metric,
       CAST(COUNTIF(order_status = 'delivered' AND order_delivered_customer_date IS NULL) AS STRING) AS value,
       '' AS note
FROM `olist001.raw.orders`
UNION ALL
SELECT 'null_check', 'orders', 'delivered_but_null_approved_at',
       CAST(COUNTIF(order_status = 'delivered' AND order_approved_at IS NULL) AS STRING), ''
FROM `olist001.raw.orders`

-- null_check：declared_monthly_revenue 没有空值，但可能用 0 代替了“未填写”
UNION ALL
SELECT 'null_check', 'closed_deals', 'declared_monthly_revenue_eq_0',
       CAST(COUNTIF(declared_monthly_revenue = 0) AS STRING),
       FORMAT('%.2f%% of %d rows', 100 * COUNTIF(declared_monthly_revenue = 0) / COUNT(*), COUNT(*))
FROM `olist001.raw.closed_deals`

-- T3 准备：origin 的取值分布（原始值，未标准化）
UNION ALL
SELECT 'category_values', 'mql_leads', CONCAT('origin_', IFNULL(origin, 'NULL')), CAST(COUNT(*) AS STRING), ''
FROM `olist001.raw.mql_leads`
GROUP BY origin

-- date_logic：won_date 早于 first_contact_date 的那一条明细
UNION ALL
SELECT 'date_logic', 'closed_deals', CONCAT('won_before_first_contact_', c.mql_id),
       CAST(DATE_DIFF(DATE(c.won_date), m.first_contact_date, DAY) AS STRING),
       FORMAT('first_contact=%s won=%s', CAST(m.first_contact_date AS STRING), CAST(DATE(c.won_date) AS STRING))
FROM `olist001.raw.closed_deals` c
JOIN `olist001.raw.mql_leads` m USING (mql_id)
WHERE DATE(c.won_date) < m.first_contact_date

-- date_logic：成交日期晚于订单数据截止日的商家（这些商家在订单数据里不可能有订单）
UNION ALL
SELECT 'date_logic', 'closed_deals', 'won_after_order_cutoff',
       CAST(COUNTIF(DATE(won_date) > (SELECT order_cutoff FROM params)) AS STRING),
       'won_date > 2018-08-30'
FROM `olist001.raw.closed_deals`

-- observation_window：按成交月份看匹配率，判断“对不上订单”是集中在晚成交的商家，还是普遍存在
UNION ALL
SELECT 'observation_window', 'closed_deals', CONCAT('match_rate_won_', won_month),
       FORMAT('%.4f', COUNTIF(matched) / COUNT(*)),
       FORMAT('%d of %d', COUNTIF(matched), COUNT(*))
FROM (
  SELECT FORMAT_DATE('%Y-%m', DATE(c.won_date)) AS won_month, i.seller_id IS NOT NULL AS matched
  FROM `olist001.raw.closed_deals` c
  LEFT JOIN (SELECT DISTINCT seller_id FROM `olist001.raw.order_items`) i USING (seller_id)
)
GROUP BY won_month

-- observation_window：匹配上的商家里，有多少订单早于成交日期（成交前就在卖，说明关联口径可能有问题）
UNION ALL
SELECT 'observation_window', 'closed_deals', 'matched_sellers_with_order_before_won',
       CAST(COUNT(DISTINCT IF(DATE(o.order_purchase_timestamp) < DATE(c.won_date), c.seller_id, NULL)) AS STRING),
       'won sellers having >=1 order purchased before won_date'
FROM `olist001.raw.closed_deals` c
JOIN `olist001.raw.order_items` i USING (seller_id)
JOIN `olist001.raw.orders` o USING (order_id)

-- category_values：长期停在中间状态的订单按状态拆分
UNION ALL
SELECT 'category_values', 'orders', CONCAT('stuck_', order_status), CAST(COUNT(*) AS STRING),
       'purchased >30d before cutoff'
FROM `olist001.raw.orders`
WHERE order_status IN ('shipped', 'processing', 'approved', 'invoiced', 'created')
  AND DATE(order_purchase_timestamp) < DATE_SUB((SELECT order_cutoff FROM params), INTERVAL 30 DAY)
GROUP BY order_status
)

SELECT check_name, table_name, metric, value, note
FROM results
ORDER BY check_name, table_name, metric;
