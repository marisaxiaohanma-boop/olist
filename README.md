# Olist Growth Analytics

A growth diagnosis of a Brazilian e-commerce marketplace (Olist), built on public data in BigQuery. Each project answers one part of the growth equation:

| Project | Growth lever | Core question |
|---|---|---|
| **P1 · Lead Quality vs. Lead Volume** | Acquisition | For each acquisition channel, how much GMV does one marketing-qualified lead (MQL) bring in on average? |
| **P2 · Repeat Purchase & Customer Value** | Retention | Is low repeat purchase worth investing in, and if so, in whom and how? |
| **P3 · Website Conversion Funnel** | Conversion | Where do visitors drop off, and which fix is worth the most revenue? (GA4 sample data) |

## Data pipeline

- **Warehouse:** BigQuery project `olist001`, US region
- **Layers:** `raw` (source tables, never modified) → `clean` (validated and transformed) → `analysis` (project outputs)
- **Sources:** [Olist Marketing Funnel](https://www.kaggle.com/olistbr/marketing-funnel-olist) and [Brazilian E-Commerce Public Dataset](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce) (Kaggle)

Data is cleaned in four phases before any analysis: **Setup → Quality Checklist → Transform → Reconciliation**. The Quality Checklist only inspects the data; Transform is the only phase that writes clean tables.

## Repository layout

```
cleaning/                  one folder per cleaning step
  S1_setup_load/           load raw CSVs into BigQuery
  S2_env_check/            verify billing, region, table expiry
  S3_repo_setup/           this repository
  Q1_quality_checklist/    data quality checks (read-only)  ← start here
  T1_type_cast/            type conversion
  T2_grain/                aggregate one-to-many tables to order level
  T3_standardize/          normalize categorical values
  T4_build_clean/          build clean tables
  R1_reconciliation/       raw vs. clean reconciliation
p1_lead_quality/           P1 analysis
p2_repeat_purchase/        P2 analysis
p3_ga4_funnel/             P3 analysis
scripts/                   reproducible load scripts
docs/cleaning_log.md       every data issue found and how it was handled
```

Each step and project folder follows the same structure, so every number can be traced back to the query that produced it:

| File | Contents |
|---|---|
| `README.md` | Purpose, method, and decision rules for the step |
| `sql/` | Queries, numbered in run order |
| `results/` | Query output (CSV) |
| `findings.md` | What the results mean and what was decided |

Raw CSVs are not committed. `scripts/00_setup_and_load.sh` downloads them from Kaggle and loads them into BigQuery.

## Status

| Step | Status |
|---|---|
| S1–S3 Setup | ✅ Done |
| Q1 Quality Checklist (stage 1) | ✅ Done. See [findings](cleaning/Q1_quality_checklist/findings.md) |
| T1–T4, R1 (stage 1) | Not started |
| P1 | Not started |
