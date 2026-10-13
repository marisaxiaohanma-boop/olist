# Olist Growth Analytics

A growth diagnosis of a Brazilian e-commerce marketplace (Olist), built on public data in BigQuery. Each project answers one part of the growth equation:

| Project | Growth lever | Core question |
|---|---|---|
| **P1 · Lead Quality vs. Lead Volume** | Acquisition | For each acquisition channel, how much GMV does one marketing-qualified lead (MQL) bring in on average? |
| **P2 · Repeat Purchase & Customer Value** | Retention | Is low repeat purchase worth investing in, and if so, in whom and how? |
| **P3 · Website Conversion Funnel** | Conversion | Where do visitors drop off, and which fix is worth the most revenue? (GA4 sample data) |

## Data pipeline

- **Warehouse:** BigQuery project `olist001`, US region
- **Layers:** `raw` (source tables, never modified) → `clean` (transformed per project) → `analysis` (project outputs)
- **Sources:** [Olist Marketing Funnel](https://www.kaggle.com/olistbr/marketing-funnel-olist) and [Brazilian E-Commerce Public Dataset](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce) (Kaggle)

## How the data is cleaned

Cleaning happens in two layers. Folders are named **phase letter + step number + short name** (e.g. `Q1_quality_checklist` = Quality checklist, step 1).

**1. Shared: set up and validate.** Done once, for all projects, and doesn't change any data.

| Prefix | Phase | Question it answers |
|---|---|---|
| **S** | **Setup** | Is the raw data loaded and the environment ready? |
| **Q** | **Quality checklist** | Is the raw data a faithful record of how the business works: does it follow the business model, is critical data missing, do the tables join? |

| Folder | What it does |
|---|---|
| [`S1_setup_load`](cleaning/S1_setup_load) | Load the Kaggle CSVs into BigQuery `raw` |
| [`S2_env_check`](cleaning/S2_env_check) | Verify billing, region (US), and that raw tables won't expire |
| [`S3_repo_setup`](cleaning/S3_repo_setup) | Set up this repository |
| [`Q1_quality_checklist`](cleaning/Q1_quality_checklist) | Check raw data against a standard written in advance. **Start here:** [findings](cleaning/Q1_quality_checklist/findings.md) |

**2. Per project: transform and reconcile.** Done after each project's scoping, because what counts as "clean" depends on the business question (e.g. which order statuses count as revenue is a P1 decision).

| Prefix | Phase | Question it answers |
|---|---|---|
| **T** | **Transform** | Given what this project needs, how do we fix the issues Q found and build its `clean` tables? |
| **R** | **Reconciliation** | Did the transform drop or duplicate anything by mistake? Every difference must be explained in the [cleaning log](docs/cleaning_log.md) |

| Folder | Project |
|---|---|
| [`cleaning/p1_lead_quality`](cleaning/p1_lead_quality) | P1 |
| [`cleaning/p2_repeat_purchase`](cleaning/p2_repeat_purchase) | P2 (P2's tables are first added to Q1 as stage 2) |

## Repository layout

```
cleaning/                  shared setup + validation, then per-project transform (see above)
p1_lead_quality/           P1 scoping and analysis
p2_repeat_purchase/        P2 scoping and analysis
p3_ga4_funnel/             P3 data prep and analysis (GA4 data, not Olist)
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
| Q1 Quality Checklist (stage 1: P1's tables) | ✅ Done. See [findings](cleaning/Q1_quality_checklist/findings.md) |
| P1 scoping → P1 transform & reconciliation → P1 analysis | Not started |
| Q1 stage 2 (P2's tables) → P2 | Not started |
