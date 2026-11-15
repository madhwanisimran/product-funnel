--sessions table, one row per visit-day--
CREATE OR REPLACE TABLE `sylvan-agility-511910-s9.funnel_project.sessions` AS
WITH base AS (
  SELECT
    CONCAT(fullVisitorId, '-', CAST(visitId AS STRING)) AS session_id,
    fullVisitorId AS full_visitor_id,
    visitId AS visit_id,
    PARSE_DATE('%Y%m%d', date) AS session_date,
    TIMESTAMP_SECONDS(visitStartTime) AS visit_start_ts,
    visitNumber AS visit_number,
    channelGrouping AS channel_grouping,
    device.deviceCategory AS device_category,
    geoNetwork.country AS country,
    totals.pageviews AS pageviews,
    totals.hits AS total_hits,
    totals.bounces IS NOT NULL AS is_bounce,
    totals.transactions AS transactions,
    totals.transactionRevenue / 1000000 AS session_revenue_usd
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
  WHERE _TABLE_SUFFIX BETWEEN '20160801' AND '20170801'
)
SELECT
  CONCAT(session_id, '-', FORMAT_DATE('%Y%m%d', session_date)) AS session_key,
  session_id,
  full_visitor_id,
  visit_id,
  session_date,
  visit_start_ts,
  visit_number,
  channel_grouping,
  device_category,
  country,
  pageviews,
  total_hits,
  is_bounce,
  transactions,
  session_revenue_usd,
  COUNT(*) OVER (PARTITION BY session_id) > 1 AS is_split_visit,
  ROW_NUMBER() OVER (PARTITION BY session_id ORDER BY visit_start_ts) > 1 AS is_continuation_row
FROM base;

SELECT
  COUNT(*) AS rows_total,
  COUNT(DISTINCT session_key) AS distinct_session_keys,
  COUNTIF(is_split_visit) AS split_rows,
  COUNTIF(is_continuation_row) AS continuation_rows,
  COUNTIF(transactions IS NOT NULL) AS purchase_sessions,
  ROUND(SUM(session_revenue_usd), 2) AS total_revenue_usd
FROM `sylvan-agility-511910-s9.funnel_project.sessions`;

SELECT
  COUNTIF(n_dates = 2) AS pairs_on_different_dates,
  COUNT(*) AS split_visits
FROM (
  SELECT session_id, COUNT(DISTINCT session_date) AS n_dates
  FROM `sylvan-agility-511910-s9.funnel_project.sessions`
  WHERE is_split_visit
  GROUP BY session_id
);

--the one split visit that has a purchase in both halves--
SELECT
  session_key, session_date, visit_start_ts, transactions, session_revenue_usd
FROM `sylvan-agility-511910-s9.funnel_project.sessions`
WHERE session_id IN (
  SELECT session_id
  FROM `sylvan-agility-511910-s9.funnel_project.sessions`
  WHERE is_split_visit AND transactions IS NOT NULL
  GROUP BY session_id
  HAVING COUNT(*) > 1
)
ORDER BY visit_start_ts;

SELECT COUNT(*) AS visits_with_purchase_in_both_halves
FROM (
  SELECT session_id
  FROM `sylvan-agility-511910-s9.funnel_project.sessions`
  WHERE is_split_visit AND transactions IS NOT NULL
  GROUP BY session_id
  HAVING COUNT(*) > 1
);