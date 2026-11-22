# Data quality log

## Summary (fill in at the end of Phase 5)

- Checks run: \_**\_ | Issues found: \_\_** | Resolved: \_**\_ | Documented limitations: \_\_**

## Exclusion rules per metric (fill in at the end)

| Metric          | Excludes |
| --------------- | -------- |
| Funnel          | \_\_\_\_ |
| Retention       | \_\_\_\_ |
| Revenue and AOV | \_\_\_\_ |

## Entries

### DQ-01: Null pageviews

**Table / check:** sessions, pageviews IS NULL
**Rule:** a session normally has at least one pageview
**Observed:** 100 of 903,653 sessions (0.011%); detail: the 100 sessions have no pageviews, are not bounces, contain 1-13 non-page hits and no purchases.
**Treatment:** left as NULL (not imputed); excluded automatically from pageview averages
**Remaining limitation:** pageview counts exclude these sessions
**Status:** documented

### DQ-02: Ranges, dates and internal consistency

**Table / check:** sessions: date range, negatives, visit_number >= 1, hits >= pageviews, bounce vs pageviews
**Observed:** date range 2016-08-01 to 2017-08-01; 0 violations in every check
**Treatment:** none needed
**Status:** resolved (no issue)

### DQ-03: Purchases without revenue

**Table / check:** sessions, transactions set but session_revenue_usd NULL
**Observed:** 37 sessions (0.32% of 11,552 purchasing rows); 0 sessions with revenue but no transactions
**Treatment:** flagged `has_revenue_gap`; kept in purchase counts; excluded from revenue metrics. Likely the same 37 orders with NULL revenue in the orders table (to confirm in the orders audit)
**Remaining limitation:** revenue for these purchases is unknown
**Status:** documented

### DQ-04: Hit-count ceiling and extreme sessions

**Table / check:** sessions, total_hits distribution
**Observed:** maximum total_hits = 500, and the ten largest sessions all have exactly 500; 99.9th percentile = 105. Sessions at the cap:10 (5 contain a purchase); above p99.9 (105 hits): 891.Extreme sessions are kept and flagged. Automation is not assumed.
**Treatment:** kept; flagged `is_hit_cap_session` (== 500) and `is_extreme_session` (> 105). Funnel and retention reported with and without flagged sessions.
**Remaining limitation:** capped sessions are truncated (events after hit 500 are not recorded); automation is suspected, not proven
**Status:** documented

### DQ-05: Category values

**Observed:** channel (8 values) and device (3 values) are clean; "(Other)" channel has 120 sessions; country has 1,468 sessions "(not set)" and no nulls; "(not set)" kept as its own value and excluded from country comparisons.
**Treatment:** "(Other)" channel grouped as "Other" and excluded from channel comparisons; odd country values: \_\_\_\_
**Status:** documented

### DQ-06: Split visits

**Observed:** 898 visits split across midnight Pacific into 1,796 rows (every group has 2 rows); flags `is_split_visit` and `is_continuation_row` agree (1,796 and 898)
**Treatment:** both rows kept; a return requires a higher visit_number
**Status:** resolved

### DQ-07: Events nulls

**Observed:** transaction_id is null on 1,034,759 of 1,059,291 events (97.7%); the 24,532 non-null values are exactly the purchase hits. No other column has nulls.
**Treatment:** none needed. **Status:** resolved

### DQ-08: Event timing

**Observed:** 0 events before session start, 0 more than 24 h after; max offset 4.48 h. Event range 2016-08-01 07:06 UTC to 2017-08-02 06:58 UTC (= US Pacific 1 Aug 2016 to 1 Aug 2017).
**Treatment:** none needed. **Status:** resolved

### DQ-09: Skipped funnel steps

**Observed:** purchase without cart 1,440 (12.5%), purchase without view 2,179 (18.9%), checkout without cart 3,272 (14.6%), cart without view 5,612 (11.2%), purchase before cart 43 (0.4%), cart before view 1,998 (4.5%).
**Treatment:** not repaired. Funnel reported two ways (strict sequential and stage reached).
**Remaining limitation:** causes unknown (possible carts from earlier sessions, adds from list pages, midnight splits).
**Status:** documented

### DQ-10: Sessions with ecommerce activity

**Observed:** 133,343 sessions (14.8%) contain an ecommerce action; events per session median 5, 99.9th percentile 108, max 463.
**Treatment:** none. The funnel base is sessions with a product view (124,188).
**Status:** documented

### DQ-11: Orders: nulls

**Observed:** revenue_usd null on 37 orders (0.32%); tax_usd null on 3,469 (30.0%); shipping_usd null on 72 (0.6%). No other nulls (confirm with the re-run of 4.1).
**Treatment:** the 37 orders are flagged `is_valid_order = False`, kept in order counts and excluded
from revenue and AOV. They are the same 37 purchases that have no session revenue.
**Remaining limitation:** revenue for these purchases is unknown. **Status:** documented

### DQ-12: Orders: revenue distribution and outliers

**Observed:** median $54.28, mean $141.33, maximum $23,952.56. Top 10 orders = 8.0% of revenue, top 1% = 21.7%. 12 orders exceed the 99.9th percentile ($5,553.20), worth about $142,300 (8.7%).
**Treatment:** kept; flagged `is_large_order_outlier`. Revenue metrics reported with and without them; median reported beside AOV. The extreme orders come from sessions of 15-227 hits, so they look like real shopping sessions.
**Remaining limitation:** whether very large orders are bulk or wholesale purchases is unknown.
**Status:** documented

### DQ-13: Orders vs sessions revenue gap

**Observed:** total gap $87,358.30 (order higher). Median difference $5.00; 5th-95th percentile $1-$9; 97 orders differ by more than $100. Excluding the 14 largest differences the gap is $64,074.65. Order revenue equals session revenue + shipping on 1 order only (+ tax: 1).
**Treatment:** order-level revenue used as the headline; session total used only as a cross-check.
**Remaining limitation:** cause of the systematic few-dollar difference is unexplained.
**Status:** documented

### DQ-14: Tax and shipping

**Observed:** shipping exceeds revenue on 373 orders, tax exceeds revenue on 8. No negatives.
**Interpretation:** evidence suggests revenue excludes shipping and tax (inference, not proof).
**Treatment:** revenue reported as recorded; tax and shipping reported separately where used.
**Status:** documented

### DQ-15: Order ID date and session links

**Observed:** all 11,552 IDs contain a valid date, and it equals order_date in every case; 0 orders without a matching session.
**Treatment:** none needed. **Status:** resolved (no issue)

### DQ-16: Heavy buyers

**Observed:** top visitor 33 orders ($2,689.34); second 16 orders ($88,395.15, about 5.4% of order revenue); 971 of 10,022 buying visitors (9.7%) have 2+ orders; the top 5 buyers account for 95 orders (0.8%). Excluding the top 5 buyers, the share with 2+ orders is about 9.6%.
**Treatment:** kept; flagged `is_heavy_buyer` (10+ valid orders). Revenue per user reported with and without heavy buyers and large-order outliers.
**Remaining limitation:** cookies identify browsers, so heavy buyers may be shared browsers or business
purchasers; this cannot be determined from the data. **Status:** documented

### DQ-17: Users: consistency

**Observed:** no missing values; first_session_date equals each visitor's earliest session_date for all 714,167 visitors; is_true_new agrees with first_visit_number in every row.
**Treatment:** none needed. **Status:** resolved (no issue)

### DQ-18: Out-of-order visit numbers

**Observed:** 123 visitors have a session numbered 1 but an earlier session (by timestamp) numbered above 1.
**Treatment:** flagged `has_inconsistent_visit_number`; excluded from cohorts (is_true_new = False).
**Remaining limitation:** cause not determined. **Status:** documented

### DQ-19: Cohort eligibility

**Observed:** 699,633 visitors enter cohort analysis (701,500 true new minus 1,867 in the one-day Aug 2017 cohort). Visitors excluded as already returning at first sight: 12,667 in total, the most in Aug 2016 (3,473) because the data starts then.
**Treatment:** flag `in_cohort_analysis`. Day-N cells without enough follow-up time are left blank.
**Status:** documented

### DQ-20: Heavy visitors

**Observed:** sessions per visitor: median 1, 99.9th percentile 15, max 278; 635 visitors above 15 sessions. The most active visitor (278 sessions) is also the top buyer by revenue (16 orders, $88,395.15, about 5.4% of order revenue, 9 visitors have 10 or more orders).
**Treatment:** flagged `is_heavy_visitor` (> 15 sessions) and `is_heavy_buyer` (10+ valid orders).
Revenue per user is reported with and without them.
**Remaining limitation:** nature of these browsers is unknown (business buyer, reseller, shared
browser). **Status:** documented
