# Q1 · Quality Checklist

- **Purpose:** before changing any data, check the raw tables against a standard written in advance. The findings tell each project what its transform step needs to handle.
- **Standard:** [checklist.md](checklist.md) (v1)
- **Method:** each check is one query block in [`sql/01_quality_checklist.sql`](sql/01_quality_checklist.sql). Every block outputs the same five columns (`check_name, table_name, metric, value, note`), combined with `UNION ALL` into one result table.
- **Results:** [`results/`](results/)
- **Findings:** [findings.md](findings.md)
- **Status:** ✅ Stage 1 done (2026-10-13). Stage 2 tables will be added to the same files before P2.
