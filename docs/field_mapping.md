# Field Mapping: Guide fields to Google Analytics fields

Version: v2 | Last updated: 2026-10-30
Source: `bigquery-public-data.google_analytics_sample.ga_sessions_*`

Status key: **available** = used as stored | **derived** = computed from other fields

## Required fields from the project guide

| Guide field         | GA field                                               | Status    | Notes                                                                                                                                                                                                                |
| ------------------- | ------------------------------------------------------ | --------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| user_id             | `fullVisitorId`                                        | available | Identifies a browser cookie, not a person. `userId` is empty in all 903,653 sessions and is not used.                                                                                                                |
| signup_date         | `date` of the user's first session (`visitNumber = 1`) | derived   | No true registration date exists. First observed session is the proxy. Visitors whose first observed `visitNumber` is above 1 (1.8%) are excluded from cohorts.                                                      |
| acquisition_channel | `channelGrouping`                                      | available | Main channel field (8 values). Session-level for funnel analysis, first-session value for user-level analysis. 120 "(Other)" sessions grouped as "Other". `trafficSource.source` / `medium` kept as optional detail. |
| device_type         | `device.deviceCategory`                                | available | desktop, mobile, tablet. Same session-level vs first-session rule as channel.                                                                                                                                        |
| event_id            | `fullVisitorId` + `visitId` + `hits.hitNumber`         | derived   | GA has no event ID, so one is built from these three fields.                                                                                                                                                         |
| user_id (events)    | `fullVisitorId`                                        | available | Same as above.                                                                                                                                                                                                       |
| event_timestamp     | `visitStartTime` + `hits.time`                         | derived   | `visitStartTime` is a UTC epoch in seconds. `hits.time` is milliseconds since session start.                                                                                                                         |
| event_name          | `hits.eCommerceAction.action_type`                     | derived   | Codes mapped to names: 2 = product_view, 3 = add_to_cart, 4 = remove_from_cart, 5 = checkout, 6 = purchase. Codes 0 (no action) and 1 (list click) are not funnel stages.                                            |
| session_id          | `fullVisitorId` + `visitId`                            | derived   | `visitId` alone is not unique across visitors, so both fields are combined.                                                                                                                                          |
| order_id            | `hits.transaction.transactionId`                       | available | One order = one distinct `transactionId`. A purchase appears on about two hits, so count distinct IDs.                                                                                                               |
| order_date          | `date` of the session containing the order             | derived   | Uses the same day-boundary rule as retention.                                                                                                                                                                        |
| order_value         | `hits.transaction.transactionRevenue` / 1,000,000      | derived   | Stored in millionths of USD. Currency confirmed as USD. Whether tax and shipping are included is to be confirmed in Phase 3.                                                                                         |

## Additional fields used in the analysis

| Purpose                            | GA field                                                   | Status    | Notes                                                                                              |
| ---------------------------------- | ---------------------------------------------------------- | --------- | -------------------------------------------------------------------------------------------------- |
| New-user flag                      | `visitNumber`                                              | available | 1 for a visitor's first session. Depends on the browser cookie.                                    |
| Bounce flag                        | `totals.bounces`                                           | available | 1 for a bounce, NULL otherwise (not 0). A qualifying return uses `IS NULL`.                        |
| Session purchase check             | `totals.transactions`                                      | available | NULL when there is no purchase. 11,552 sessions have one.                                          |
| Session revenue (cross-check only) | `totals.transactionRevenue`                                | available | In millionths. Used to reconcile order-level revenue.                                              |
| Session size                       | `totals.pageviews`, `totals.hits`                          | available | Used in the bot and outlier checks (Phase 5).                                                      |
| Country segment (optional)         | `geoNetwork.country`                                       | available | Optional segment.                                                                                  |
| Products in an order (optional)    | `hits.item.productCategory`, `itemQuantity`, `itemRevenue` | available | One order can have several items, so joining items to orders can multiply revenue. Join carefully. |

## Fields not used

| Field                                          | Reason                                                |
| ---------------------------------------------- | ----------------------------------------------------- |
| `visitorId`                                    | Deprecated and mostly empty. `fullVisitorId` is used. |
| `userId`                                       | Empty in all sessions.                                |
| `appInfo.*`                                    | Mobile app fields, not relevant to this web store.    |
| `adwordsClickInfo`, ad fields (`dfp*`, `ads*`) | Not needed for this analysis.                         |
| `customDimensions`                             | Repeated custom field, not needed.                    |

## Fields missing from the guide's list

None of the guide's required fields is missing. Two are derived from proxies (signup date and event name), and `userId` is not usable as a logged-in identifier.

## Open items

- [ ] Confirm whether `transactionRevenue` includes tax and shipping (Phase 3)
- [ ] Verify the time zone of `date` against the UTC date of `visitStartTime` (Phase 3)
- [ ] Check action types 7 (refund) and 8 (checkout options) across the full period (Phase 3)
