# Data dictionary (clean tables)

## sessions: one row per ____ (grain)
| Column | Type | Meaning | Source field | Caveat | Nulls | Example |
|---|---|---|---|---|---|---|
| `session_key` | str | | | | 0 | 8126641317511045537-1470067930-20160801 |
| `session_id` | str | | | | 0 | 8126641317511045537-1470067930 |
| `full_visitor_id` | str | | | | 0 | 8126641317511045537 |
| `visit_id` | Int64 | | | | 0 | 1470067930 |
| `session_date` | datetime64[ms] | | | | 0 | 2016-08-01 00:00:00 |
| `visit_start_ts` | datetime64[us, UTC] | | | | 0 | 2016-08-01 16:12:10+00:00 |
| `visit_number` | Int64 | | | | 0 | 1 |
| `channel_grouping` | str | | | | 0 | Social |
| `device_category` | str | | | | 0 | desktop |
| `country` | str | | | | 0 | Serbia |
| `pageviews` | Int64 | | | | 100 | 1 |
| `total_hits` | Int64 | | | | 0 | 1 |
| `is_bounce` | boolean | | | | 0 | True |
| `transactions` | Int64 | | | | 892,101 | 1 |
| `session_revenue_usd` | float64 | | | | 892,138 | 7.99 |
| `is_split_visit` | boolean | | | | 0 | False |
| `is_continuation_row` | boolean | | | | 0 | False |
| `is_hit_cap_session` | boolean | | | | 0 | False |
| `is_extreme_session` | boolean | | | | 0 | False |
| `has_revenue_gap` | bool | | | | 0 | False |
| `is_valid_purchase_row` | bool | | | | 0 | False |

## events: one row per ____ (grain)
| Column | Type | Meaning | Source field | Caveat | Nulls | Example |
|---|---|---|---|---|---|---|
| `event_id` | str | | | | 0 | 5278722127498674654-1485950241-20170201- |
| `session_key` | str | | | | 0 | 5278722127498674654-1485950241-20170201 |
| `session_id` | str | | | | 0 | 5278722127498674654-1485950241 |
| `full_visitor_id` | str | | | | 0 | 5278722127498674654 |
| `event_ts` | datetime64[us, UTC] | | | | 0 | 2017-02-01 12:07:01.385000+00:00 |
| `hit_number` | Int64 | | | | 0 | 77 |
| `hit_type` | str | | | | 0 | EVENT |
| `action_type` | str | | | | 0 | 1 |
| `event_name` | str | | | | 0 | product_list_clicked |
| `transaction_id` | str | | | | 1,034,759 | ORD201705122054 |

## orders: one row per ____ (grain)
| Column | Type | Meaning | Source field | Caveat | Nulls | Example |
|---|---|---|---|---|---|---|
| `transaction_id` | str | | | | 0 | ORD20160801563 |
| `session_id` | str | | | | 0 | 2788555723243018631-1470077433 |
| `session_key` | str | | | | 0 | 2788555723243018631-1470077433-20160801 |
| `full_visitor_id` | str | | | | 0 | 2788555723243018631 |
| `order_date` | datetime64[ms] | | | | 0 | 2016-08-01 00:00:00 |
| `order_ts` | datetime64[us, UTC] | | | | 0 | 2016-08-01 19:09:17.567000+00:00 |
| `hit_number` | Int64 | | | | 0 | 63 |
| `revenue_usd` | float64 | | | | 37 | 258.0 |
| `tax_usd` | float64 | | | | 3,469 | 6.0 |
| `shipping_usd` | float64 | | | | 72 | 7.0 |
| `currency` | str | | | | 0 | USD |
| `is_valid_order` | bool | | | | 0 | True |
| `is_large_order_outlier` | bool | | | | 0 | False |

## users: one row per ____ (grain)
| Column | Type | Meaning | Source field | Caveat | Nulls | Example |
|---|---|---|---|---|---|---|
| `full_visitor_id` | str | | | | 0 | 4948931523491427211 |
| `first_visit_number` | Int64 | | | | 0 | 1 |
| `first_session_date` | datetime64[ms] | | | | 0 | 2016-08-01 00:00:00 |
| `cohort_month` | datetime64[ms] | | | | 0 | 2016-08-01 00:00:00 |
| `is_true_new` | boolean | | | | 0 | True |
| `first_channel` | str | | | | 0 | Organic Search |
| `first_category` | str | | | | 0 | desktop |
| `first_country` | str | | | | 0 | (not set) |
| `has_inconsistent_visit_number` | boolean | | | | 0 | False |
| `in_cohort_analysis` | boolean | | | | 0 | True |
| `is_heavy_visitor` | bool | | | | 0 | False |
| `valid_orders` | int64 | | | | 0 | 0 |
| `is_heavy_buyer` | bool | | | | 0 | False |
