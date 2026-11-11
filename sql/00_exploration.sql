-- =====================================================
-- Step 1: Date range of the dataset
-- Purpose: confirm the dataset covers the expected date range
-- Run date: 2026-10-28 | Period: full dataset (2016-08-01 to 2017-08-01)
-- Result: 2016-08-01 is the first date, 2017-08-01 is the last date, 366 days present, 366 expected days
-- =====================================================
SELECT
  MIN(date) AS first_date,
  MAX(date) AS last_date,
  COUNT(DISTINCT date) AS days_present,
  DATE_DIFF(PARSE_DATE('%Y%m%d', MAX(date)),
            PARSE_DATE('%Y%m%d', MIN(date)), DAY) + 1 AS expected_days
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`;

-- =====================================================
-- Step 2: Count sessions and visitors per month
-- Purpose: how much data is there, and is it spread evenly?
-- Run date: 2026-10-28 | Period: full dataset (2016-08-01 to 2017-08-01)
-- Result: Sessions per month range from about 62,000 to 114,000, with the peak in Nov 2016 (113,972) and a high Oct 2016 (97,506)
-- =====================================================
SELECT
  SUBSTR(date, 1, 6) AS year_month,
  COUNT(*) AS sessions,
  COUNT(DISTINCT fullVisitorId) AS visitors
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
GROUP BY year_month
ORDER BY year_month;

-- =====================================================
-- Step 3: New vs returning visitors
-- Purpose: how many visitors first appear with visitNumber = 1
-- Run date: 2026-10-28 | Period: full dataset (2016-08-01 to 2017-08-01)
-- Result: 714,167 visitors, 98.2% true new
-- =====================================================
WITH first_seen AS (
  SELECT
    fullVisitorId,
    MIN(visitNumber) AS min_visit_number
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
  GROUP BY fullVisitorId
)
SELECT
  COUNT(*) AS total_visitors,
  COUNTIF(min_visit_number = 1) AS true_new_visitors,
  COUNTIF(min_visit_number > 1) AS already_returning,
  ROUND(100 * COUNTIF(min_visit_number = 1) / COUNT(*), 1) AS pct_true_new
FROM first_seen;

-- =====================================================
-- Step 4: E-commerce action types
-- Purpose: Which e-commerce action codes exist, and how many hits each has?
-- Run date: 2026-10-28 | Period: full dataset (2016-08-01 to 2017-08-01)
-- Result: 
--Code	Likely meaning	Sessions
--0	No e-commerce action (ordinary page hits)	64,582
--1	Click on a product in a list	9,222
--2	Product detail view	9,211
--3	Add to cart	3,386
--4	Remove from cart	606
--5	Checkout	1,538
--6	Purchase	697
-- =====================================================
SELECT
  h.eCommerceAction.action_type AS action_type,
  COUNT(*) AS hits,
  COUNT(DISTINCT CONCAT(fullVisitorId, '-', CAST(visitId AS STRING))) AS sessions
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`,
  UNNEST(hits) AS h
WHERE _TABLE_SUFFIX BETWEEN '20170101' AND '20170131'
GROUP BY action_type
ORDER BY action_type;

-- =====================================================
-- Step 5: Looks at channels and devices
-- Purpose: which categories exist and how big is each?
-- Run date: 2026-10-28 | Period: full dataset (2016-08-01 to 2017-08-01)
-- Result: The 8 channels add up to 903,653, and the 3 devices also add up to 903,653.Organic Search is the biggest channel (381,561), then Social (226,117), Direct (143,026) and Referral (104,838). Paid Search (25,326), Affiliates (16,403) and Display (6,262) are small. (Other) --has only 120 sessions.
--Devices: desktop 664,479, mobile 208,725, tablet 30,449.
-- =====================================================
SELECT
  channelGrouping,
  COUNT(*) AS sessions
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
GROUP BY channelGrouping
ORDER BY sessions DESC;
SELECT
  device.deviceCategory AS device_category,
  COUNT(*) AS sessions
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
GROUP BY device_category
ORDER BY sessions DESC;

-- =====================================================
-- Step 6a: How common are purchases?
-- Purpose: baseline session conversion (share of sessions with a transaction)
-- Run date: 2026-10-28 | Period: full dataset (2016-08-01 to 2017-08-01)
-- Result: sessions = 903,653 | sessions_with_transaction = ____ | pct = 1.28%
-- =====================================================
SELECT
  COUNT(*) AS sessions,
  COUNT(totals.transactions IS NOT NULL) AS sessions_with_transactions,
  ROUND(100 * COUNTIF(totals.transactions IS NOT NULL) / COUNT(*), 2) AS pct_with_transaction
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`;

-- =====================================================================
-- Step 6b: Do revenue values look right after dividing by 1,000,000?
-- Purpose: confirm the micros-to-currency conversion gives plausible prices
-- Run date: 2026-10-28 | Period: 2017-01-01 to 2017-01-07
-- Result: values such as 19.99, 15.99, 104.78 (plausible); one order of 1942.0
-- =====================================================================
SELECT 
  fullVisitorId,
  visitId,
  totals.transactions AS transactions,
  totals.transactionRevenue AS revenue_raw,
  totals.transactionRevenue / 1000000 AS revenue_units
FROM`bigquery-public-data.google_analytics_sample.ga_sessions_*`
WHERE _TABLE_SUFFIX BETWEEN '20170101' AND '20170107'
  AND totals.transactionRevenue IS NOT NULL
LIMIT 20;
 
-- =====================================================================
-- Step 6c: Currency of transactions
-- Purpose: confirm the currency used in transaction hits
-- Run date: 2026-10-28 | Period: 2017-01-01 to 2017-01-31
-- Result: USD, 1,442 hits
-- =====================================================================
SELECT
  h.transaction.currencyCode AS currency,
  COUNT(*) AS hits
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`,
  UNNEST(hits) AS h
WHERE _TABLE_SUFFIX BETWEEN '20170101' AND '20170131'
  AND h.transaction.transactionId IS NOT NULL
GROUP BY currency
ORDER BY hits DESC;

-- =====================================================================
-- Step 6d: How empty is userId?
-- Purpose: decide whether a logged-in user ID is usable (we use fullVisitorId)
-- Run date: 2026-10-28 | Period: full dataset
-- Result: sessions = 903,653 | sessions_with_user_id = ____
-- =====================================================================
SELECT 
  COUNT(*) AS sessions,
  COUNTIF(userId IS NOT NULL) AS sessions_with_user_id
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`;

-- =====================================================================
-- Step 6e: Purchase hits vs distinct orders vs purchasing sessions
-- Purpose: check whether one purchase is recorded on several hits
--          (earlier: 1,442 hits across 697 sessions in Jan 2017)
-- Run date: 2026-10-28 | Period: 2017-01-01 to 2017-01-31
-- Result: purchase_hits = 1442 | distinct_transaction_ids = 697 | purchase_sessions = 697
-- =====================================================================
SELECT
  COUNT(*) AS purchase_hits,
  COUNT(DISTINCT h.transaction.transactionId) AS distinct_transaction_ids,
  COUNT(DISTINCT CONCAT(fullVisitorId, '-', CAST(visitId AS STRING))) AS purchase_sessions
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`,
  UNNEST(hits) AS h
WHERE _TABLE_SUFFIX BETWEEN '20170101' AND '20170131'
  AND h.transaction.transactionId IS NOT NULL;