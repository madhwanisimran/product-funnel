USE funnel_db;

-- row counts
SELECT 'users' AS tbl, COUNT(*) AS n FROM users
UNION ALL SELECT 'sessions', COUNT(*) FROM sessions
UNION ALL SELECT 'events', COUNT(*) FROM events
UNION ALL SELECT 'orders', COUNT(*) FROM orders;

-- users flags
SELECT SUM(is_true_new) AS true_new, SUM(in_cohort_analysis) AS in_cohort,
	   SUM(has_inconsistent_visit_number) AS inconsistent,
       SUM(is_heavy_visitor) AS heavy_visitors, SUM(is_heavy_buyer) AS heavy_buyers
FROM users;

-- sessions
SELECT ROUND(SUM(session_revenue_usd), 2) AS revenue, COUNT(transactions) AS sessions_with_tx,
       SUM(is_continuation_row) AS continuation, SUM(is_split_visit) AS split_rows,
       SUM(is_hit_cap_session) AS hit_cap, SUM(is_extreme_session) AS extreme,
       SUM(has_revenue_gap) AS revenue_gap, SUM(is_valid_purchase_row) AS valid_purchase_rows
FROM sessions;

-- events
SELECT SUM(event_name = 'purchase') AS purchase_hits,
	   COUNT(DISTINCT CASE WHEN event_name = 'purchase' THEN session_key END) AS purchase_sessions,
       COUNT(transaction_id) AS non_null_tx
FROM events;

-- orders
SELECT ROUND(SUM(revenue_usd), 2) AS revenue, SUM(is_valid_order) AS valid_orders,
       SUM(is_large_order_outlier) AS outliers, COUNT(DISTINCT transaction_id) AS distinct_orders
FROM orders;

-- orphans
SELECT
  (SELECT COUNT(*) FROM events e LEFT JOIN sessions s ON e.session_key = s.session_key
   WHERE s.session_key IS NULL) AS orphan_events,
  (SELECT COUNT(*) FROM orders o LEFT JOIN sessions s ON o.session_key = s.session_key
   WHERE s.session_key IS NULL) AS orphan_orders,
  (SELECT COUNT(*) FROM sessions s LEFT JOIN users u ON s.full_visitor_id = u.full_visitor_id
   WHERE u.full_visitor_id IS NULL) AS orphan_sessions;
   
SELECT (SELECT COUNT(*) FROM users    WHERE full_visitor_id = '0011338928267756760') AS in_users,
       (SELECT COUNT(*) FROM sessions WHERE full_visitor_id = '0011338928267756760') AS in_sessions;
       
SELECT MIN(event_ts) AS first_event, MAX(event_ts) AS last_event FROM events;

SELECT SUM(session_date <> DATE(visit_start_ts)) AS rows_with_different_date FROM sessions;       

SELECT ROUND(SUM(revenue_usd), 2) AS revenue_correct FROM orders;

SELECT ROUND(SUM(o.revenue_usd), 2) AS revenue_inflated
FROM orders o
JOIN events e ON e.session_key = o.session_key;

SELECT ROUND(SUM(o.revenue_usd), 2) AS revenue_from_cart_sessions
FROM orders o
WHERE EXISTS (SELECT 1 FROM events e
              WHERE e.session_key = o.session_key AND e.event_name = 'add_to_cart');


