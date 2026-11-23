CREATE OR REPLACE TABLE `sylvan-agility-511910-s9.funnel_project.orders_table` AS
WITH tx AS (
  SELECT
    h.transaction.transactionId AS transaction_id,
    CONCAT(fullVisitorId,'-',CAST(visitId AS STRING),'-',date) AS session_key,
    CONCAT(fullVisitorId,'-',CAST(visitId AS STRING)) AS session_id,
    fullVisitorId AS full_visitor_id,
    PARSE_DATE('%Y%m%d', date) AS order_date,
    TIMESTAMP_ADD(TIMESTAMP_SECONDS(visitStartTime), INTERVAL h.time MILLISECOND) AS order_ts,
    h.hitNumber AS hit_number,
    h.transaction.transactionRevenue / 1000000 AS revenue_usd,
    h.transaction.transactionTax / 1000000 AS tax_usd,
    h.transaction.transactionShipping / 1000000 AS shipping_usd,
    h.transaction.currencyCode AS currency,
    ROW_NUMBER() OVER(PARTITION BY h.transaction.transactionId) AS row_num
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`,
    UNNEST(hits) AS h
  WHERE _TABLE_SUFFIX BETWEEN '20160801' AND '20170801'
    AND h.transaction.transactionId IS NOT NULL
)
SELECT 
  transaction_id,session_id,session_key,full_visitor_id,order_date,
  order_ts,hit_number,revenue_usd,tax_usd,shipping_usd,currency
FROM tx
WHERE row_num = 1;

-- O1: rows and distinct IDs. Expected: both 11,552
SELECT COUNT(*) AS rows_total, COUNT(DISTINCT transaction_id) AS distinct_ids
FROM `sylvan-agility-511910-s9.funnel_project.orders_table`;

-- O2: total order revenue vs session-level total ($1,540,071.24), plus bad values
SELECT
  ROUND(SUM(revenue_usd), 2) AS orders_revenue_usd,
  COUNTIF(revenue_usd IS NULL OR revenue_usd <= 0) AS null_or_nonpositive_revenue,
  ROUND(MAX(revenue_usd), 2) AS max_order_usd,
  ROUND(AVG(revenue_usd), 2) AS avg_order_usd
FROM `sylvan-agility-511910-s9.funnel_project.orders_table`;

-- O3: orders per purchasing session row (how many session rows have more than one order?)
SELECT orders_in_row, COUNT(*) AS session_rows
FROM (
  SELECT session_key, COUNT(*) AS orders_in_row
  FROM `sylvan-agility-511910-s9.funnel_project.orders_table`
  GROUP BY session_key
)
GROUP BY orders_in_row
ORDER BY orders_in_row;

-- O4: are tax, shipping and currency populated?
SELECT
  COUNTIF(tax_usd IS NOT NULL) AS rows_with_tax,
  COUNTIF(shipping_usd IS NOT NULL) AS rows_with_shipping,
  ROUND(SUM(tax_usd), 2) AS total_tax,
  ROUND(SUM(shipping_usd), 2) AS total_shipping,
  COUNTIF(currency != 'USD') AS non_usd_orders
FROM `sylvan-agility-511910-s9.funnel_project.orders_table`;

SELECT
  COUNT(*) AS orders,
  COUNTIF(ABS(o.revenue_usd - IFNULL(s.session_revenue_usd, 0)) < 0.01) AS same_revenue,
  COUNTIF(o.revenue_usd - IFNULL(s.session_revenue_usd, 0) >= 0.01) AS order_higher,
  COUNTIF(IFNULL(s.session_revenue_usd, 0) - o.revenue_usd >= 0.01) AS session_higher,
  COUNTIF(s.session_revenue_usd IS NULL) AS session_revenue_null,
  ROUND(SUM(o.revenue_usd - IFNULL(s.session_revenue_usd, 0)), 2) AS total_gap
FROM `sylvan-agility-511910-s9.funnel_project.orders_table` AS o
JOIN `sylvan-agility-511910-s9.funnel_project.sessions` AS s
  ON o.session_key = s.session_key;

SELECT
  o.transaction_id,
  o.revenue_usd AS order_revenue,
  s.session_revenue_usd AS session_revenue,
  ROUND(o.revenue_usd - IFNULL(s.session_revenue_usd, 0), 2) AS diff,
  o.tax_usd,
  o.shipping_usd
FROM `sylvan-agility-511910-s9.funnel_project.orders_table` AS o
JOIN `sylvan-agility-511910-s9.funnel_project.sessions` AS s
  ON o.session_key = s.session_key
ORDER BY ABS(o.revenue_usd - IFNULL(s.session_revenue_usd, 0)) DESC
LIMIT 15;

-- Ten largest orders
SELECT transaction_id, order_date, revenue_usd, tax_usd, shipping_usd
FROM `sylvan-agility-511910-s9.funnel_project.orders_table`
ORDER BY revenue_usd DESC
LIMIT 10;

-- The 37 null or non-positive orders
SELECT
  COUNTIF(revenue_usd IS NULL) AS null_revenue,
  COUNTIF(revenue_usd = 0) AS zero_revenue,
  COUNTIF(revenue_usd < 0) AS negative_revenue
FROM `sylvan-agility-511910-s9.funnel_project.orders_table`;