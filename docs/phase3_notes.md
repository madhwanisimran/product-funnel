# Phase 3 notes: Flattening practice

Date used for all practice queries: 2017-01-05 only

## Practice 1: Raw session rows

**Question:** What does a raw session row look like before flattening?
**Query:** sql/bigquery/01_unnest.sql
**Result:**

- Each row is one session, identified by combining `fullVisitorId` and `visitId`.
- `visitNumber` counts a visitor's sessions: 1 for the first observed session, above 1 for
  a returning visitor.
- `bounces` and `transactions` are mostly NULL, not 0.
  **Interpretation:** Null means "no bounce" or "no purchase", so rules must use IS NULL / IS NOT NULL.

## Practice 2: Unnesting hits

**Question:** What happens to a session's columns when hits are unnested?
**Query:** Query 2
**Result:** The same session columns repeat on one row per hit. `action_type` is stored as
(text : '6').
**Interpretation:** Unnesting repeats the parent session's values beside every hit.

### Practice 3: sessions versus hit rows

| sessions | hits by ARRAY_LENGTH | hit rows after UNNEST |
| -------- | -------------------- | --------------------- |
| 2,193    | 10,962               | 10,962                |

**Interpretation:** Both counting methods agree. About 5.0 hits per session. (An earlier figure of
71,080 hit rows came from a different query and was discarded.)

### Practice 4: the multiplication trap

| 4a (no unnest) | 4b (after UNNEST of hits) | Ratio |
| -------------- | ------------------------- | ----- |
| $8,859.97      | $390,354.79               | 44.06 |

**Interpretation:** Both queries sum totals.transactionRevenue. After UNNEST, each purchasing
session's revenue is repeated once per hit, so the sum counts it many times. The ratio (44) is the
revenue-weighted average hits per purchasing session, far above the 5 hits of an average session.
**Decision:** Session-level values are summed only in the sessions table. Hit-level data
(events, orders) never carries session-level revenue.

## Why unnesting repeats session columns

Unnesting flattens the nested hits list so each hit becomes its own row, and the parent
session's columns are copied onto every one of those rows.

## Step 3: Sessions table (full period)

**Question:** Does the sessions table match the raw data and the rulebook?
**Query:** sql/bigquery/02_esessions.sql;
**Result:**
| Check | Result |
|---|---|
| Rows | 903,653 |
| Distinct session_id | 902,755 (898 extra rows share an ID) |
| Purchasing sessions | 11,552 |
| Total session revenue (USD) | 1,540,071.24 |
| Bounce share | 49.9% |
| Sessions where `date` differs from the UTC date | 228,884 of 903,653 (25.3%) |

**Interpretation:** Row count and purchase count reconcile with the earlier exploration.
About 25% of sessions have a `date` that differs from the UTC date, so `date` is not in UTC.
898 session IDs are duplicated (investigation pending).
**Decision / rulebook update:** Use `session_date` for every day boundary. Time-zone test
and duplicate decision recorded below once run.
**Caveats:** Revenue total is session-level and is reconciled with orders in Step 5.

### Duplicate session IDs

**Question:** Why do 898 session IDs appear twice?
**Result:** 903,653 rows, 902,755 distinct IDs. No row is an exact copy of another. 1,796 rows
(898 IDs x 2) are affected, including 38 purchase rows ($3,208.35 of session revenue).
**Interpretation:** Each pair is one visit that crossed midnight Pacific time. Google Analytics
splits the session at midnight, but the daily export keeps the same visitId.
**Decision:** Keep both rows. Added a unique `session_key` and the flags `is_split_visit` and
`is_continuation_row`. A return requires a higher `visit_number`, so continuation rows
never count as returns.
**Caveats:** Funnel sequences may be broken for 0.1% of sessions.

### Time zone of `date`

**Result:** 0 sessions differ from the US Pacific date (`America/Los_Angeles`); 228,884 differ
from the UTC date.
**Decision:** `session_date` = US Pacific date. Use it for all day boundaries. Convert to Pacific
before any time-of-day analysis.

## Step 4: Events table (full period)

**Question:** Does the events table reconcile with the sessions table and the Phase 2 findings?
**Query:** sql/bigquery/03_events.sql;
| event_name | hits | sessions |
|---|---|---|
| product_list_clicked | 445,760 | 124,494 |
| product_view | 362,607 | 124,188 |
| add_to_cart | 121,427 | 50,139 |
| checkout | 88,019 | 22,407 |
| remove_from_cart | 16,946 | 9,615 |
| purchase | 24,532 | 11,552 |

Total rows: 1,059,291 (unique event_id: 1,059,291). Orphan events: 0. Purchase sessions: 11,552
from events and 11,552 from sessions. Purchase hits 24,532 vs 11,552 distinct transaction IDs
(2.12 hits per order).
**Interpretation:** Counts fall along the shopping path. Refund (7) and checkout options (8)
never occur. Distinct transaction IDs equal purchasing session rows, so each purchasing row
appears to hold one order.
**Decision / rulebook update:** Codes 7 and 8 removed from consideration. Orders are counted by
distinct transactionId and funnel purchases by distinct session, never by hit.
**Caveats:** Counts are sessions with at least one hit of each type, with no sequence rule.
The split-visit purchase was not inspected; the matching IDs above weakly suggest the two
halves hold different orders.

## Step 5: Orders table

**Question:** Does the orders table (one row per distinct transactionId) reconcile with sessions?
**Query:** sql/bigquery/04_orders.sql; checks O1-O4
**Result:**
| Check | Result |
|---|---|
| Rows / distinct transaction_id | 11,552 / 11,552 |
| Orders per purchasing session row | 1 in all 11,552 rows |
| Orders revenue (USD) | 1,627,429.54 |
| Sessions revenue (USD) | 1,540,071.24 |
| Gap | 87,358.30 (orders 5.7% higher) |
| Null or non-positive revenue | 37 orders |
| Max / average order | 23,952.56 / 141.33 |
| Tax present / shipping present | 8,083 / 11,480 orders; non-USD: 0 |

**Interpretation:** Every purchasing session row holds exactly one distinct order, so the
midnight-split visit contains two different orders (the earlier "same purchase twice"
hypothesis is retired). `totals.transactions` counts transaction hits, not orders.
The order-level and session-level revenue totals disagree by 5.7%; cause:

**Revenue gap diagnostics (Diagnostics 1-3):**

- Orders matching session revenue to the cent: 0 of 11,552. Order higher: 11,395.
  Session higher: 120. Session revenue null: 37 (likely the same 37 orders with null order revenue).
- Total gap: $87,358.30 (5.7%). The 14 largest differences net to about +$23,000 and go in both
  directions. Shipping on those rows is $9-15 and tax is mostly null, so neither explains them.
- Largest orders: top 10 total about $130,400 (8% of order revenue). Max $23,952.56.
  Three of the top 10 are also among the largest order-vs-session mismatches.
- Invalid orders: 37, all null revenue (0 zero, 0 negative).
  **Interpretation:** The two revenue fields are filled separately and disagree systematically.
  Cause not determined. Revenue concentrates in a few very large orders.
  **Decision:** Headline revenue = order-level revenue; session-level total used as a cross-check.
  Flag (not delete) invalid and outlier orders in Phase 5. Report median order value beside AOV and a
  with/without-outliers sensitivity check.
  **Caveats:** Revenue is uncertain by about 5.7%. Whether revenue includes tax and shipping remains
  unresolved..

## Step 6: Users table

**Question:** Does the users table (one row per visitor) match the Phase 2 counts?
**Query:** sql/bigquery/05_users.sql;
**Result:**
| Check | Result |
|---|---|
| Rows / distinct visitors | 714,167 / 714,167 |
| True new | 701,500 (Phase 2 count by lowest visit number: 701,623; difference 123) |
| Cohort sizes (true new) | Aug 2016: 58,226 | Sep: 55,553 | Oct: 80,871 | Nov: 94,732 | Dec: 57,692 | Jan 2017: 48,458 | Feb: 47,700 | Mar: 54,034 | Apr: 51,815 | May: 48,012 | Jun: 48,074 | Jul: 54,466 | Aug 2017: 1,867 |
**Interpretation:** Cohort sizes sum to 701,500. Nov and Oct 2016 are the largest cohorts (holiday
season). The Aug 2017 cohort is one day. The 123-visitor difference is due to out-of-order visit numbers: for these visitors the earliest
session by timestamp has visit_number above 1 although a session numbered 1 exists later
(tie-breaker test T1 made no difference; check T2 = 123). Cause not determined.
**Decision / rulebook update:** `is_true_new` uses the earliest session by time. Exclude the Aug 2017
cohort. Leave blank grid cells for cohorts without enough follow-up time (Day 30 needs first
session on or before 2 Jul 2017; the Jul 2017 cohort is almost entirely ineligible).
**Caveats:** Cohorts are defined by first observed session in US Pacific dates.
