-- Data QA diagnosis: why are 1,655 orders still "in progress" months after purchase?
-- Question: are these orders genuinely in transit, or did their final outcome never get written back?
-- Scope: in-progress orders purchased more than 30 days before the order-data cutoff (2018-08-30). Read-only.
-- Output: check_name, table_name, metric, value, note

WITH params AS (
  SELECT DATE '2018-08-30' AS order_cutoff
),

orders AS (
  SELECT
    o.*,
    order_status IN ('shipped', 'processing', 'approved', 'invoiced', 'created') AS in_progress,
    DATE(order_purchase_timestamp) < DATE_SUB((SELECT order_cutoff FROM params), INTERVAL 30 DAY) AS older_than_30d,
    FORMAT_DATE('%Y-Q%Q', DATE(order_purchase_timestamp)) AS purchase_quarter
  FROM `olist001.raw.orders` o
),

results AS (

-- 1. For each stuck status: which lifecycle timestamps exist, how old the orders are,
--    and whether they're past the delivery date promised to the customer
SELECT 'category_values' AS check_name, 'orders' AS table_name,
       CONCAT('stuck_', order_status) AS metric,
       CAST(COUNT(*) AS STRING) AS value,
       FORMAT('approved=%d carrier=%d delivered=%d | median age %d days | past promised date=%d',
              COUNTIF(order_approved_at IS NOT NULL),
              COUNTIF(order_delivered_carrier_date IS NOT NULL),
              COUNTIF(order_delivered_customer_date IS NOT NULL),
              APPROX_QUANTILES(DATE_DIFF((SELECT order_cutoff FROM params), DATE(order_purchase_timestamp), DAY), 2)[OFFSET(1)],
              COUNTIF(DATE(order_estimated_delivery_date) < (SELECT order_cutoff FROM params))) AS note
FROM orders
WHERE in_progress AND older_than_30d
GROUP BY order_status

-- 2. Stuck share by purchase quarter: a single system outage would show as a spike
UNION ALL
SELECT 'category_values', 'orders',
       CONCAT('pct_stuck_', purchase_quarter),
       FORMAT('%.2f', 100 * COUNTIF(in_progress) / COUNT(*)),
       FORMAT('%d of %d orders', COUNTIF(in_progress), COUNT(*))
FROM orders
WHERE older_than_30d
GROUP BY purchase_quarter
)

SELECT check_name, table_name, metric, value, note
FROM results
ORDER BY metric;
