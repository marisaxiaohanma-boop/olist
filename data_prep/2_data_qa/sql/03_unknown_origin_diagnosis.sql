-- Data QA diagnosis: why is lead origin missing for 14.5% of MQLs?
-- Question: is "unknown" origin random noise, a one-time tracking outage, or a systematic gap?
-- Read-only. Output: check_name, table_name, metric, value, note

WITH leads AS (
  SELECT
    m.mql_id,
    m.landing_page_id,
    FORMAT_DATE('%Y-%m', m.first_contact_date) AS contact_month,
    m.origin IS NULL OR m.origin = 'unknown' AS is_unknown,  -- NULL and the literal 'unknown' mean the same thing
    c.mql_id IS NOT NULL AS is_won
  FROM `olist001.raw.mql_leads` m
  LEFT JOIN `olist001.raw.closed_deals` c USING (mql_id)
),

pages AS (
  SELECT landing_page_id, COUNT(*) AS leads, COUNTIF(is_unknown) AS unknown_leads, COUNTIF(is_won) AS won
  FROM leads
  GROUP BY landing_page_id
),

results AS (

-- 1. Over time: a one-time outage would show up as a spike in specific months
SELECT 'unknown_origin' AS check_name, 'mql_leads' AS table_name,
       CONCAT('pct_unknown_', contact_month) AS metric,
       FORMAT('%.1f', 100 * COUNTIF(is_unknown) / COUNT(*)) AS value,
       FORMAT('%d of %d leads', COUNTIF(is_unknown), COUNT(*)) AS note
FROM leads
GROUP BY contact_month

-- 2. Close rate: if unknown leads behave like everyone else, missing origin is closer to random
UNION ALL
SELECT 'unknown_origin', 'mql_leads', IF(is_unknown, 'won_rate_unknown', 'won_rate_known'),
       FORMAT('%.1f', 100 * COUNTIF(is_won) / COUNT(*)),
       FORMAT('%d won of %d leads', COUNTIF(is_won), COUNT(*))
FROM leads
GROUP BY is_unknown

-- 3. Landing pages: a tagging gap would concentrate unknowns on specific pages
UNION ALL
SELECT 'unknown_origin', 'mql_leads', 'unknown_on_top_unknown_page',
       CAST(MAX(unknown_leads) AS STRING),
       (SELECT FORMAT('page %s: %d leads, %d unknown, %d won', landing_page_id, leads, unknown_leads, won)
        FROM pages ORDER BY unknown_leads DESC LIMIT 1)
FROM pages
UNION ALL
SELECT 'unknown_origin', 'mql_leads', 'total_unknown', CAST(SUM(unknown_leads) AS STRING), ''
FROM pages
UNION ALL
SELECT 'unknown_origin', 'mql_leads', 'pages_total', CAST(COUNT(*) AS STRING), 'distinct landing_page_id'
FROM pages
UNION ALL
SELECT 'unknown_origin', 'mql_leads', 'pages_100pct_unknown', CAST(COUNTIF(unknown_leads = leads) AS STRING),
       FORMAT('%d leads on these pages', SUM(IF(unknown_leads = leads, leads, 0)))
FROM pages
)

SELECT check_name, table_name, metric, value, note
FROM results
ORDER BY metric;
