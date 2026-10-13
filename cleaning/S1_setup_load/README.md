# S1 · Load raw data

- **Purpose:** load the Kaggle CSVs into `olist001.raw` in a way that can be re-run safely.
- **Method:** [`scripts/00_setup_and_load.sh`](../../scripts/00_setup_and_load.sh). It strips the `olist_` prefix and `_dataset` suffix from table names, renames `marketing_qualified_leads` to `mql_leads`, skips `geolocation` (not used by any project), and overwrites existing tables on each run.
- **Rule:** `raw` must contain exactly the 10 tables the SQL expects. Missing tables are re-loaded, never edited by hand in the console.
- **Status:** ✅ Done. `geolocation` had been loaded by mistake and was dropped on 2026-10-13; `raw` now holds 10 tables.
- **Note:** the original load was not recorded. The script was written afterwards from this step's spec so the load can be reproduced from a fresh clone. It has not been re-run against the existing `raw` tables.
