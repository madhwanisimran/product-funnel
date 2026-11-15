CREATE OR REPLACE TABLE `sylvan-agility-511910-s9.funnel_project.users` AS
WITH ranked AS(
  SELECT
    full_visitor_id, visit_number, session_date, channel_grouping, device_category,
    country,
    ROW_NUMBER() OVER(
      PARTITION BY full_visitor_id
      ORDER BY visit_start_ts, visit_number
    ) AS rn
    FROM `sylvan-agility-511910-s9.funnel_project.sessions`
)
SELECT
  full_visitor_id,
  visit_number AS first_visit_number,
  session_date AS first_session_date,
  DATE_TRUNC(session_date, MONTH) AS cohort_month,
  visit_number = 1 AS is_true_new,
  channel_grouping AS first_channel,
  device_category AS first_category,
  country AS first_country
FROM ranked
WHERE rn = 1;

SELECT
  COUNT(*) AS rows_total,
  COUNT(DISTINCT full_visitor_id) AS distinct_visitors,
  COUNTIF(is_true_new) AS true_new
FROM `sylvan-agility-511910-s9.funnel_project.users`;

SELECT cohort_month, COUNT(*) AS new_visitors
FROM `sylvan-agility-511910-s9.funnel_project.users`
WHERE is_true_new
GROUP BY cohort_month
ORDER BY cohort_month;

WITH ordered AS (
  SELECT
    full_visitor_id, visit_number, visit_start_ts,
    ROW_NUMBER() OVER (PARTITION BY full_visitor_id ORDER BY visit_start_ts, visit_number) AS rn
  FROM `sylvan-agility-511910-s9.funnel_project.sessions`
),
per_visitor AS (
  SELECT
    full_visitor_id,
    MIN(visit_number) AS min_visit_number,
    MAX(IF(rn = 1, visit_number, NULL)) AS first_by_time_visit_number
  FROM ordered
  GROUP BY full_visitor_id
)
SELECT COUNT(*) AS conflicting_visitors
FROM per_visitor
WHERE min_visit_number = 1 AND first_by_time_visit_number > 1;
