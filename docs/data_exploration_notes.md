# DATA EXPLORATION NOTES
DATASET: Google Analytics Sample (BigQuery public data, Google Merchandise Store)
Date run: 2026-10-29 | Queries: sql/bigquery//00_exploration.sql

---

## Step 1: First and the last dates

**Question:** What is the full date range, and are there any missing days?

**Query:** `sql/00_exploration.sql`, query 1 (full period, date run: 2026-10-22)

**Result:**
| first_date | last_date | days_present | expected_days |
|---|---|---|---|
| 2016--08-01 | 2017-08-01 | 366 | 366 |

**Interpretation:** The date runs from 1 Aug 2016 to 1 Aug 2017, with no missing days.

**Decision / rulebook update:** Fill the period in section B of the rulebook. For Day 30
retention, a user is eligible only if their first session is on or before 2 July 2017.

**Caveats:** 1 Aug 2017 is a single day, so the last month is partial.

--- 
## Step 2: Sessions and visitors per month
**Question:** How much data is there, and is it spread evenly?

**Query:** `sql/00_exploration.sql`, Step 2 (full dataset)

**Result:**
| year_month | sessions | visitors |
|---|---|---|
| 201608 | 74,759 | 61,699 |
| 201609 | 71,032 | 59,121 |
| 201610 | 97,506 | 84,901 |
| 201611 | 113,972 | 99,734 |
| 201612 | 79,124 | 63,839 |
| 201701 | 64,694 | 53,041 |
| 201702 | 62,192 | 51,364 |
| 201703 | 69,931 | 57,888 |
| 201704 | 67,126 | 55,681 |
| 201705 | 65,371 | 52,233 |
| 201706 | 63,578 | 52,067 |
| 201707 | 71,812 | 58,569 |
| 201708 | 2,556 | 2,293 |

**Interpretation:** Traffic peaks in Nov 2016 (113,972 Sessions) and is also high in Oct 2016, which fits the holiday season. Other months range from about 62,000 to 80,000. Aug 2017 is only one day of data.

**Decision/rulebook update:** Exclude Aug 2017 from monthly trend and cohort comparisons.
Note seasonality (Oct-Dec) as a caveat for retention and revenue comparisons.

**Caveats:** Visitors per month are distinct within that month, so monthly visitors counts cannot be added together to get total visitors.

---

## Step 3: New versus returning visitors

**Question:** How many visitors are true new visitors (first observed visit number = 1)?

**Query:** `sql/00_exploration.sql`, query 3 (full period, date run: 2026-10-22)

**Result:**
| total_visitors | true_new_visitors | already_returning | pct_true_new |
|---|---|---|---|
| 714,167 | 701,623 | 12,544 | 98.2% |

**Interpretation:** Almost all visitors are first seen on their first-ever visit. Only
1.8% were already returning when the data starts.

**Decision / rulebook update:** Keep the "new users only" rule for cohorts. Excluding
12,544 visitors removes little data. (Rulebook section C unchanged.)

**Caveats:** Visit number is set by Google Analytics and depends on the cookie, so a
cleared cookie makes a returning person look new.

---

## Step 4: Ecommerce action types (January 2017)

**Question:** Which action_type value exists, and how many hits and sessions has each?

**Query:** `sql/00_exploration.sql` Step 4 (2017-01-01 to 2017-01-31)

**Result:**
| action_type | hits | sessions |
|---|---|---|
| 0 | 228,608 | 64,582 |
| 1 | 30,900 | 9,222 |
| 2 | 25,787 | 9,211 |
| 3 | 7,342 | 3,386 |
| 4 | 960 | 606 |
| 5 | 5,035 | 1,538 |
| 6 | 1,442 | 697 |

**Interpretation:** Values 0 to 6 all appear. Counts fall along the shopping path in a sensible order. Provisional meaning (TO CONFIRM in the official schema documentation):
0 = no ecommerce action, 1 = product list click, 2 = product detail view, 3 = add to cart,
4 = remove from cart, 5 = checkout, 6 = purchase.

**Decision / rulebook update:** Funnel stages are 2 -> 3 -> 5 -> 6 (pending confirmation).
Only about 14% of sessions (9,211 of 64,582) have a product view, so the base chosen for
overall conversion changes the headline rate. Report both bases.

**Caveats:** One month only. Counts are sessions with at least one hit of each type, with
no sequence rule applied, so any funnel rates from this table are a sanity check, not a result.

---

## Step 5: Channels and devices

**Question:** Which channel and device categories exist, and how big is each?

**Query:** 00_exploration.sql, Step 5 (full dataset)

**Result (channelGrouping):**
| channelGrouping | sessions |
|---|---|
| Organic Search | 381,561 |
| Social | 226,117 |
| Direct | 143,026 |
| Referral | 104,838 |
| Paid Search | 25,326 |
| Affiliates | 16,403 |
| Display | 6,262 |
| (Other) | 120 |

**Result (device category):**
| device_category | sessions |
|---|---|
| desktop | 664,479 |
| mobile | 208,725 |
| tablet | 30,449 |

**Interpretation:** Both lists add up to 903,653 sessions, so nothing is missing. Organic
Search is the largest channel. Social is large by traffic, so its conversion needs checking
later. Desktop dominates.

**Decision / rulebook update:** Use channelGrouping as the main channel field. Treat
(Other) (120 sessions) as an "Other" group or exclude it from channel comparisons.
Be cautious reading percentages for Display and (Other), which are small.

**Caveats:** channelGrouping is assigned per session, so first-touch channel for a user
must be taken from the user's first session.

---

## Step 6: Purchases, revenue, currency, userId

### 6a: Share of sessions with a transaction

**Question:** What share of sessions include a purchase (baseline session conversion)?

**Query:** 00_exploration.sql, Step 6a (full dataset)

**Result:**
| sessions | sessions_with_transaction | pct_with_transaction |
|---|---|---|
| 903,653 | 11,552 | 1.28% |

**Interpretation:** About 1 in 78 sessions ends in a purchase. This is the baseline
session-to-purchase conversion rate for the whole period.

**Decision / rulebook update:** Report session-to-purchase conversion (all sessions as the
base, 1.28%) alongside the product-view-based conversion, and label each clearly. This
baseline will feed the A/B test sample-size calculation in Phase 13.

**Caveats:** Counted with totals.transactions IS NOT NULL. In Phase 3, reconcile this
against the count of distinct transactionIds from the hits, since the two should be close.

### 6b: Revenue units
**Result:** After dividing by 1,000,000, values look like store prices (19.99, 15.99,
104.78, 223.6). One order was 1,942.0.
**Decision:** Check large orders as possible outliers in the Phase 5 data-quality audit.

### 6c: Currency
**Result:** USD, 1,442 hits (January 2017).
**Decision:** Currency confirmed as USD. Update the rulebook from "assumed" to "confirmed".

### 6d: userId
**Result:** sessions with a non-null userId = 0 of 903,653. fullVisitorId is present on
all 903,653 sessions.
**Decision:** userId is unusable. fullVisitorId is the user identifier. Add to limitations:
no logged-in user ID is available.

### 6e: Purchase hits versus orders
**Result:** purchase_hits = 1,442 | distinct_transaction_ids = 697 | purchase sessions = 697
(January 2017).
**Interpretation:** Each order appears on about 2 hits (1,442 / 697 = 2.07), and in
January each purchasing session had exactly one order.
**Decision:** Count orders with COUNT(DISTINCT transactionId) and funnel purchases with
sessions, never with hits. In Phase 3, check across the full period whether any session has
more than one distinct transactionId. In Phase 5, check for duplicate transaction IDs.

**Caveats (Step 6):** The two-hits-per-order pattern is measured for one month only.

---

## Step 7: Documentation checks

**Question:** What do the official docs say about time zone, bounce, visitNumber and action_type?

**Source:** Google Analytics sample dataset documentation (checked 2026-10-30)

**Result:**
| Item | Finding |
|---|---|
| Time zone | visitStartTime is a UTC epoch timestamp. The time zone of the `date` field is NOT yet verified (it may follow the Analytics view, not UTC). |
| Bounce | Session with a single interaction hit or pageview. totals.bounces = 1 for a bounce, NULL otherwise. |
| visitNumber | Sequential session number per visitor: 1 for the first session, +1 for each later session. |
| action_type 0 | Unknown / unspecified (ordinary hits with no ecommerce action) |
| action_type 1 | Click through of product lists |
| action_type 2 | Product detail views |
| action_type 3 | Add product(s) to cart |
| action_type 4 | Remove product(s) from cart |
| action_type 5 | Check out |
| action_type 6 | Completed purchase |

**Interpretation:** The action_type codes match the shopping-path pattern in the Step 4 counts.

**Decision / rulebook update:** Funnel stages confirmed as 2 -> 3 -> 5 -> 6; code 4 analysed
separately; codes 7 and 8 not seen in January 2017, to check across the full period.
A non-bounce session is identified with totals.bounces IS NULL.
Day boundaries use the `date` field; compare it with the UTC date of visitStartTime in Phase 3.

**Caveats:** Time zone of `date` unverified. visitNumber depends on the browser cookie.

---

## Rulebook updates to make (add a change-log line for each)

- [ ] Period: 1 Aug 2016 to 1 Aug 2017; Aug 2017 treated as partial month
- [ ] Confirmed action_type codes (after Step 7)
- [ ] Currency confirmed as USD
- [ ] Channel field: channelGrouping; handling of (Other)
- [ ] userId unusable; fullVisitorId is the user
- [ ] Time zone (after Step 7)