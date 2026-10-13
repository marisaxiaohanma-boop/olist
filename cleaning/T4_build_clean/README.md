# T4 · Build clean tables

- **Purpose:** lock in T1–T3 so all analysis reads only from `clean`.
- **Method:** one SQL file per clean table in `sql/`. Which tables and columns to build is decided in each project's scoping step.
- **Rule:** re-run `rows_completion` and `distinct_primary_key` on every clean table to confirm its grain.
- **Status:** Not started.
