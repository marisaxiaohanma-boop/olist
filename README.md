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

## How the data is cleaned

Before any analysis, the data goes through four phases. Each cleaning folder is named **phase letter + step number + short name**, so `T2_grain` is the second Transform step.

| Prefix | Phase | Question it answers | Changes data? |
|---|---|---|---|
| **S** | **Setup** | Is the raw data loaded and the environment ready? | Loads `raw` only |
| **Q** | **Quality checklist** | Is the raw data a faithful record of how the business works: does it follow the business model, is critical data missing, do tables join? | No (read-only) |
| **T** | **Transform** | How do we fix what Q found, so analysis can trust the data? | Yes, writes `clean` |
| **R** | **Reconciliation** | Did cleaning drop or duplicate anything by mistake? | No (verifies `clean` against `raw`) |

| Folder | What it does |
|---|---|
| [`S1_setup_load`](cleaning/S1_setup_load) | Load the Kaggle CSVs into BigQuery `raw` |
| [`S2_env_check`](cleaning/S2_env_check) | Verify billing, region (US), and that raw tables won't expire |
| [`S3_repo_setup`](cleaning/S3_repo_setup) | Set up this repository |
| [`Q1_quality_checklist`](cleaning/Q1_quality_checklist) | Check raw data against a standard written in advance. **Start here:** [findings](cleaning/Q1_quality_checklist/findings.md) |
| [`T1_type_cast`](cleaning/T1_type_cast) | Make dates and amounts usable for calculations |
| [`T2_grain`](cleaning/T2_grain) | Roll one-to-many tables (e.g. several items per order) up to one row per order, so joins don't double-count revenue |
| [`T3_standardize`](cleaning/T3_standardize) | Make category values consistent (e.g. map missing channel and `unknown` to one group) |
| [`T4_build_clean`](cleaning/T4_build_clean) | Build the clean tables that analysis reads from |
| [`R1_reconciliation`](cleaning/R1_reconciliation) | Prove that every row and every R$ of GMV dropped between raw and clean is explained in the [cleaning log](docs/cleaning_log.md) |

Cleaning runs in two stages: stage 1 covers the five tables P1 needs, and stage 2 adds the tables for P2 before P2 starts.

## Repository layout

```
cleaning/                  data cleaning, one folder per step (see above)
p1_lead_quality/           P1 analysis
p2_repeat_purchase/        P2 analysis
p3_ga4_funnel/             P3 analysis
scripts/                   reproducible load scripts
docs/cleaning_log.md       every data issue found and how it was handled
docs/findings_standard.md  how findings are written and reviewed
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
