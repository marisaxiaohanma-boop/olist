# 1 · Setup

| Task | What was done | Status |
|---|---|---|
| **Load raw data** | [`00_setup_and_load.sh`](00_setup_and_load.sh) downloads both Olist datasets from Kaggle and loads them into BigQuery `olist001.raw`. Table names drop the `olist_` prefix and `_dataset` suffix; `marketing_qualified_leads` becomes `mql_leads`; `geolocation` is skipped (no project uses it). Re-running overwrites tables, so it never appends duplicates | ✅ 10 tables loaded |
| **Check the environment** | Billing is enabled; `raw`, `clean`, and `analysis` datasets are all in the US region (required to query the GA4 public dataset in P3); `raw` has no table expiration | ✅ All pass |
| **Set up the repository** | This repo: one folder per step, each with `sql/`, `results/`, and `findings.md`, so every number traces back to the query that produced it | ✅ Done |

**Notes**
- `geolocation` was loaded by mistake at first and dropped on 2026-10-13 (see [data prep log](../../docs/data_prep_log.md)).
- The original load wasn't recorded; the script was written afterwards from the setup spec so the load can be reproduced from a fresh clone. It hasn't been re-run against the existing `raw` tables.
