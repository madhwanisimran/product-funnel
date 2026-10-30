# Metric Definitions (Rulebook): Product Funnel, Conversion & Retention Analytics

Version: v2 | Last updated: 2026-10-30

## CHANGE LOG

| Date       | Section | Change                                                                                  | Reason                         |
| ---------- | ------- | --------------------------------------------------------------------------------------- | ------------------------------ |
| 2026-10-22 | All     | v1 draft written                                                                        | Initial rulebook               |
| 2026-10-30 | A       | Made audience, decision and questions specific; defined conversion                      | v1 was too vague to test       |
| 2026-10-30 | B       | Filled period (2016-08-01 to 2017-08-01); marked Aug 2017 partial; added keys to grain  | Phase 2, Steps 1-2             |
| 2026-10-30 | C       | Added first-touch channel/device rule; added share of true new users (98.2%)            | Phase 2, Step 3; missing in v1 |
| 2026-10-30 | D       | Confirmed action codes 2, 3, 5, 6; wrote sequence rule; added second conversion version | Phase 2, Steps 4 and 7         |
| 2026-10-30 | E       | Return = totals.bounces IS NULL; per-user eligibility; grid defined; day-boundary rule  | Phase 2, Step 7; gaps in v1    |
| 2026-10-30 | F       | Currency confirmed USD; orders counted by distinct transactionId; valid-order rule      | Phase 2, Step 6                |
| 2026-10-30 | G       | Added userId empty, no cost data, obfuscated sample, partial month, seasonality         | Phase 2 findings               |

---

## A.BUSINESS CONTEXT:

1. **WHO USES THIS ANALYSIS? :**
   Primary Audience Growth Manager: Focuses on channel acquisition efficiency, return-visitor cohorts, and re-engagement strategy.Product Manager (E-commerce): Focuses on user flow, feature adoption, product listing page design, and reducing checkout friction.

2. **WHAT DECISION DOES IT SUPPORT?:**
   • Funnel Optimization: Prioritizing checkout redesigns or simplifying user steps based on where drop-offs spike.
   • Retargeting & Loyalty Programs: Determining whether to spend budget on bringing back past visitors or driving fresh top-of-funnel acquisition.
   • Channel Spend Allocation: Shifting budget toward channel groupings and referral sources that drive actual completed transactions rather than empty traffic.

3.**WHERE DO VISITORES DROP OFF BEFORE BUYING? :**
• Data Fields Used: hits (RECORD, REPEATED), totals (RECORD), visitId, fullVisitorId
• Analysis Approach: By querying the nested hits field, you can track user interaction paths across pages (e.g., product views → add to cart → checkout steps → purchase completion). Aggregating totals.visits, totals.bounces, and totals.transactions reveals drop-off rates at each stage of the funnel.
• Decision Supported: Identifies friction points and UX bottlenecks in the conversion funnel, allowing the product team to optimize checkout steps, fix broken page elements, or improve product page layouts.

4. **WHICH VISITORS RETURN AND WHICH DON'T? :**
   • Data Fields Used: fullVisitorId, visitNumber, date, visitStartTime, totals.newVisits
   • Analysis Approach: Grouping sessions by fullVisitorId and analyzing visitNumber lets you separate one-time visitors from returning users. Correlating this with date or custom segments helps determine the frequency and recency of returning traffic.
   • Decision Supported: Helps the growth team understand customer loyalty and retention patterns. It highlights which user cohorts or initial experiences lead to repeat visits, guiding loyalty campaigns, retargeting, and email marketing strategies.

5. **WHICH ACQUISITION CHANNELS BRING VISITORS WHO ACTUALLY BUY? :**
   • Data Fields Used: trafficSource (RECORD containing source, medium, keyword), channelGrouping, totals.transactions, totals.totalTransactionRevenue

• Analysis Approach: Joining traffic metadata (channelGrouping, trafficSource.source) with transaction totals enables you to calculate conversion rates, average order value (AOV), and total revenue generated per acquisition channel (e.g., organic search, paid search, social, direct).

• Decision Supported: Informs budget allocation and marketing spend by identifying which specific marketing channels, campaigns, or referral sources acquire high-intent users rather than just high-volume, low-converting traffic.

6. **IDENTIFYING A CONVERSION SESSION :**
   A session results in a successful purchase when totals.transactions is greater than 0 (or 1).

## B.DATA SCOPE :

**SOURCE :** The dataset used for this project has been taken from Google Analytics sample dataset on BigQuery, from the Google Merchandise Store.

**PERIOD :** 1 Aug 2016 to 1 Aug 2017 (366 days, no missing days).
Aug 2017 contains one day only, so it is a partial month and is excluded from monthly
trends and cohort comparisons.
**Size:** 903,653 sessions and 714,167 visitors.

**WHAT ONE ROW MEANS:**
-> SESSIONS : This means one row per user visit to the website identified by 'fullVisitorId' + 'visitId'.
-> EVENTS : This means one row per e-commerce action hit within a session.
-> ORDERS : This means one row per distinct 'transactionId'.

## C.USERS AND COHORTS :

- **User:** a browser cookie identified by `fullVisitorId`. `userId` is empty in all sessions
  and is not used.
  - Limitation: one person on two devices or browsers counts as two users.
- **New user:** a visitor whose first observed session has `visitNumber = 1`.
  98.2% of visitors (701,623 of 714,167) qualify.
- **Cohort and retention rule:** if a visitor's first observed session has `visitNumber > 1`,
  they visited before the data begins and their real first visit is unknown. They stay in
  overall metrics but are excluded from cohort and retention analysis.
- **Cohort:** the calendar month of the user's first session (`visitNumber = 1`).
  Monthly cohorts are more readable than weekly ones for a one-year dataset.
  The Aug 2017 cohort (one day) is excluded.
- **Channel and device attribution:**
  - Session-level analysis (funnel) uses the channel and device of that session.
  - User-level analysis (retention, revenue per user) uses the channel and device of the
    user's first session (first-touch).
  - Channel field: `channelGrouping`. The 120 "(Other)" sessions are grouped as "Other" and
    excluded from channel comparisons.
  - Device field: `device.deviceCategory`.

## D.FUNNEL

- **Level:** session-based. Each visit is evaluated on its own because shopping actions
  happen within sessions.
- **Stages (confirmed from the documentation and the data):**
  1. Product view: `action_type = 2`
  2. Add to cart: `action_type = 3`
  3. Checkout: `action_type = 5`
  4. Purchase: `action_type = 6`
- **"Reached a stage":** the session contains at least one hit of that action type.
- **Sequence rule:** a session counts at a stage only if it also reached every earlier
  stage, in time order within the session.
- **Remove from cart (4), product list click (1), refund (7), checkout options (8):** not
  funnel stages. Code 4 is analysed separately. Codes 7 and 8 are checked across the full
  period in Phase 3.
- **Formulas:**
  - Stage conversion rate = sessions reaching a stage / sessions that reached the previous
    stage x 100.
  - Drop-off rate = 100 - stage conversion rate.
- **Overall conversion (two labelled versions):**
  - **Product-view-based:** sessions with a purchase / sessions with a product view x 100.
  - **Session-to-purchase:** sessions with a purchase / all sessions x 100.
    Baseline across the period: 11,552 of 903,653 = 1.28%.
- **Data quality note:** tracking can drop or reorder events. Purchases with no recorded
  earlier step are measured and reported separately.
- **Counting rule:** funnel purchases are counted by session, never by hit. A purchase is
  recorded on about two hits (January 2017: 1,442 hits for 697 orders).

## E.RETENTION :

- **Return:** a later session of the same user with `totals.bounces IS NULL`.
  (A bounce is a session with a single interaction hit or pageview. `totals.bounces` is 1
  for a bounce and NULL otherwise.)
- **Day boundary:** the `date` field of the session. The time zone of `date` is verified
  against the UTC date of `visitStartTime` in Phase 3. Do not mix the two sources.
- **Day 0:** the date of the user's first observed session (`visitNumber = 1`).
- **Exact Day-N retention:** the user has a qualifying return session on exactly N days
  after Day 0.
- **Within Day-N retention:** the user has at least one qualifying return session on days
  1 to N after Day 0 (inclusive, excluding Day 0).
- **Eligibility (per user):** a user counts for Day N only if Day 0 + N is on or before
  1 Aug 2017. For Day 30, that means a first session on or before 2 Jul 2017.
- **Formula:** Day-N retention = eligible users in the cohort with a qualifying return /
  eligible users in the cohort x 100.
- **Retention grid:** rows are cohort months, columns are Day 1, Day 7 and Day 30,
  and each cell is a percentage of that cohort's eligible users. Cells with no eligible
  users are left blank, not shown as 0.
- **Expectation:** most visitors never return, so low retention percentages are expected
  and not an error.

## F. REVENUE AND ORDERS

- **Order:** one distinct `transactionId` from the transaction hits.
- **Valid order:** a non-null `transactionId`, revenue greater than 0, counted once
  (deduplicated). Exclusions are logged in the Phase 5 data-quality report.
- **Revenue:** `transactionRevenue` / 1,000,000 (stored in millionths of the currency).
  Currency is USD (confirmed). Whether revenue includes tax and shipping is to be
  confirmed in Phase 3.
- **Reconciliation:** the session-level `totals.transactionRevenue` is used only to
  cross-check the order-level revenue.
- **Average order value (AOV):** total revenue / number of valid orders.
- **Revenue per acquired user:** total revenue from a cohort's users / number of users in
  the cohort.
- **Repeat purchase rate:** buyers with more than one valid order / all buyers, within the
  data period. Buyers acquired late have little time to repeat, so also report a version
  restricted to buyers whose first purchase is on or before 2 Jul 2017.
- **Customer lifetime value (LTV):** not calculated. One year is too short to observe
  long-term value, and an LTV model would need extra assumptions about customer lifespan
  and churn.

## G. KNOWN LIMITATIONS

- **Cookie IDs are not people:** `fullVisitorId` identifies a browser cookie, so counts are
  distorted when someone switches devices, clears cookies or uses several browsers.
- **No true signup date and no user ID:** acquisition is based on the first observed
  session, and `userId` is empty.
- **Limited scope:** one store, one year, so findings may not generalise.
- **Obfuscated sample data:** a sample from one store, not a full business record.
- **Partial final month:** the dataset ends on 1 Aug 2017.
- **Seasonality:** traffic peaks in Oct to Dec 2016, which may affect comparisons across
  cohorts and months.
- **Tracking gaps and bots:** ad blockers, script failures and automated traffic can add noise.
- **Incomplete funnel sequences:** some purchases may lack earlier recorded steps.
- **No marketing cost data:** channel value can be compared but channel ROI cannot be
  calculated.
- **Low retention is expected:** most visitors never return.

## H. Open items (to resolve in later phases)

- [ ] Time zone of the `date` field versus UTC `visitStartTime` (Phase 3)
- [ ] Action types 7 and 8 across the full period (Phase 3)
- [ ] Whether `transactionRevenue` includes tax and shipping (Phase 3)
- [ ] Sessions with more than one distinct transactionId (Phase 3)
- [ ] Outlier orders such as the 1,942 order (Phase 5)
- [ ] Reconcile 11,552 purchase sessions against distinct transactionIds (Phase 3)
