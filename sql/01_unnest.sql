--Query 1: Period: 2017-01-05--
SELECT
  fullVisitorId,
  visitId,
  visitNumber,
  date,
  visitStartTime,
  channelGrouping,
  device.deviceCategory AS device_category,
  totals.pageviews AS pageviews,
  totals.bounces AS bounces,
  totals.transactions AS transactions
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
WHERE _TABLE_SUFFIX = '20170105'
LIMIT 20;

--Query 2: unnest the hits--
SELECT
  fullVisitorId,
  visitId,
  channelGrouping,
  h.hitNumber AS hit_number,
  h.time AS hit_time_ms,
  h.type AS hit_type,
  h.eCommerceAction.action_type AS action_type
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`,
  UNNEST(hits) AS h
WHERE _TABLE_SUFFIX = '20170105'
ORDER BY fullVisitorId, visitId, h.hitNumber
LIMIT 30;

--Query 3: sessions versus hit rows--
SELECT
  COUNT(*) AS sessions,
  SUM(ARRAY_LENGTH(hits)) AS total_hits
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
WHERE _TABLE_SUFFIX = '20170105';

--Query 4: correct session-level revenue before unnest--
SELECT
  SUM(totals.transactionRevenue) / 1000000 AS revenue_correct
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
WHERE _TABLE_SUFFIX = '20170105';

--Query 5: correct session-level revenue after unnest--
SELECT
  SUM(totals.transactionRevenue) / 1000000 as revenue_inflated
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`,
  UNNEST(hits) AS h
WHERE _TABLE_SUFFIX = '20170105';

  