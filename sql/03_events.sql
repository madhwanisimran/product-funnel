-- Purpose: one row per ecommerce action hit (action_type 1-8; code '0' = no action is excluded)
-- Output: funnel_project.events
-- Rulebook rules: action_type is a STRING; names mapped from the documented codes;
--   a purchase appears on about 2 hits, so funnels count SESSIONS, never rows
CREATE OR REPLACE TABLE `sylvan-agility-511910-s9.funnel_project.events_test` AS 
SELECT
  CONCAT(fullVisitorId,'-',CAST(visitId AS STRING),'-',date,'-',
          CAST(h.hitNumber AS STRING)) AS event_id,
  CONCAT(fullVisitorId,'-',CAST(visitId AS STRING),'-',date) AS session_key,
  CONCAT(fullVisitorId,'-',CAST(visitId AS STRING)) AS session_id,
  fullVisitorId AS full_visitor_id,
  TIMESTAMP_ADD(TIMESTAMP_SECONDS(visitStartTime), INTERVAL h.time MILLISECOND) AS event_ts,
  h.hitNumber AS hit_number,
  h.type AS hit_type,
  h.eCommerceAction.action_type AS action_type,
  CASE h.eCommerceAction.action_type
    WHEN '1' THEN 'product_list_clicked'
    WHEN '2' THEN 'product_view'
    WHEN '3' THEN 'add_to_cart'
    WHEN '4' THEN 'remove_from_cart'
    WHEN '5' THEN 'checkout'
    WHEN '6' THEN 'purchase'
    WHEN '7' THEN 'refund'
    WHEN '8' THEN 'checkout_options'
  END AS event_name,
  h.transaction.transactionId AS transaction_id
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`,
 UNNEST(hits) AS h
WHERE _TABLE_SUFFIX BETWEEN '20160801' AND '20170801'
  AND h.eCommerceAction.action_type != '0';

--hits and sessions per event type across the full period
SELECT
  event_name,
  COUNT(*) AS hits,
  COUNT(DISTINCT session_key) AS sessions
FROM `sylvan-agility-511910-s9.funnel_project.events_test`
GROUP BY event_name
ORDER BY event_name;

--events with no matching session row
SELECT COUNT(*) AS orphan_events
FROM `sylvan-agility-511910-s9.funnel_project.events_test` AS e
LEFT JOIN `sylvan-agility-511910-s9.funnel_project.sessions` AS s
  ON e.session_key = s.session_key
WHERE s.session_key IS NULL;

--purchase sessions from events versus from the sessions table
SELECT
  (SELECT COUNT(DISTINCT session_key)
   FROM `sylvan-agility-511910-s9.funnel_project.events_test`
   WHERE event_name = 'purchase') AS purchase_sessions_from_events,
  (SELECT COUNTIF(transactions IS NOT NULL)
   FROM `sylvan-agility-511910-s9.funnel_project.sessions`) AS purchase_sessions_from_sessions;

--purchase hits per distinct order across the full period
SELECT
  COUNTIF(event_name = 'purchase') AS purchase_hits,
  COUNT(DISTINCT IF(event_name = 'purchase', transaction_id, NULL)) AS distinct_transaction_ids
FROM `sylvan-agility-511910-s9.funnel_project.events_test`;

