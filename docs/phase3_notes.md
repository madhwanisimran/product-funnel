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

## Practice 3: Sessions versus hit rows

**Query:** Query 3
**Result:**
| sessions | hit rows |
|---|---|
| 2193 | 10962 |

**Interpretation:** About 4.9 hits per session on average.

## Practice 4: The multiplication trap

**Query:** Queries 4a and 4b (both sum totals.transactionRevenue / 1,000,000)
**Result:**
| Query | Revenue (USD) |
|---|---|
| 4a (no unnest, correct) | 8859.97 |
| 4b (after UNNEST of hits, inflated) | 390354.79 |
| Ratio 4b / 4a | 44.06 : 1 |

**Interpretation:** Both queries sum the same field. After UNNEST, each purchasing session's
revenue is repeated once per hit, so the sum counts it many times. The ratio is roughly the
average number of hits in a purchasing session.
**Decision:** Session-level values are summed only in the sessions table, never after unnesting hits.

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
