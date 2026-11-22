# Phase 4 notes: Extraction from BigQuery

Date run: 2026-11-16 | Notebook: notebooks/03_extract_from_bigquery.ipynb

## Steps 1-3: Extract tables to parquet

**Question:** Can the four BigQuery tables be copied to the laptop without loss?
**Method:** pandas-gbq reads each table from `sylvan-agility-511910-s9.funnel_project`; DATE columns
converted to pandas dates; each table saved as parquet in `data/raw` (not committed to Git).
**Result:**
| Table | Rows | Key date and time dtypes |
|---|---|---|
| sessions | 903,653 | session_date: datetime64[s]; visit_start_ts: datetime64[us, UTC] |
| events | 1,059,291 | event_ts: datetime64[us, UTC] |
| orders | 11,552 | order_date: datetime64[s]; order_ts: datetime64[us, UTC] |
| users | 714,167 | first_session_date, cohort_month: datetime64[s] |

## Step 4: Verification against BigQuery

All 12 checks passed (OK):

- sessions: 903,653 rows, unique `session_key`, revenue $1,540,071.24, 11,552 purchase rows
- events: 1,059,291 rows, unique `event_id`, 11,552 purchasing sessions
- orders: 11,552 rows, unique `transaction_id`, revenue $1,627,429.54
- users: 714,167 rows, 701,500 true new

**Interpretation:** The local files match BigQuery on row counts, unique keys, revenue totals,
purchase counts and the true-new count.
**Decision:** The parquet files in `data/raw` are the fixed starting point for Phase 5 and are never edited.
**Caveats:** Date columns carry no time zone (they are US Pacific dates from the `date` field);
timestamp columns are UTC. Never compare the two directly. The tables are snapshots; if the
BigQuery tables are ever rebuilt, repeat the extraction and the 12 checks.
