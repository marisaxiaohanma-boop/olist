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

## Data prep

Before any analysis, the data goes through three steps in [`data_prep/`](data_prep):

| Step | Question it answers | Changes data? | Scope |
|---|---|---|---|
| [**1 · Setup**](data_prep/1_setup) | Is the raw data loaded, and is the environment ready? | Loads `raw` only | Shared |
| [**2 · Data QA**](data_prep/2_data_qa) | Is the raw data a faithful record of how the business works: does it follow the business model, is critical data missing, do the tables join? | No | Shared |
| [**3 · Transformation**](data_prep/3_transformation) | Given what a project needs, how do we fix the issues Data QA found and build its `clean` tables, and did we lose anything? | Yes, writes `clean` | Per project (after scoping) |

Transformation is per project because what counts as "clean" depends on the business question. For example, which order statuses count as revenue is a P1 decision, not a data-quality fact.

**Start here:** [Data QA findings](data_prep/2_data_qa/findings.md)

## Repository layout

```
data_prep/
  1_setup/                 load raw data, check environment
  2_data_qa/               data quality checks (shared, read-only)
  3_transformation/        per-project transform + reconciliation
    p1_lead_quality/
    p2_repeat_purchase/
    p3_ga4_funnel/
p1_lead_quality/           P1 scoping and analysis
p2_repeat_purchase/        P2 scoping and analysis
p3_ga4_funnel/             P3 data prep and analysis (GA4 data, not Olist)
scripts/                   repo tooling (findings checker)
docs/cleaning_log.md       every data issue found and how it was handled
docs/findings_standard.md  how findings are written and reviewed
```

Each data-prep step and project follows the same structure, so every number can be traced back to the query that produced it:

| File | Contents |
|---|---|
| `README.md` | Purpose, method, and decision rules for the step |
| `sql/` | Queries, numbered in run order |
| `results/` | Query output (CSV) |
| `findings.md` | What the results mean and what was decided |

Raw CSVs are not committed. [`data_prep/1_setup/00_setup_and_load.sh`](data_prep/1_setup/00_setup_and_load.sh) downloads them from Kaggle and loads them into BigQuery.

## Status

| Step | Status |
|---|---|
| 1 · Setup | ✅ Done |
| 2 · Data QA, stage 1 (P1's tables) | ✅ Done. See [findings](data_prep/2_data_qa/findings.md) |
| P1 scoping → P1 transformation → P1 analysis | Not started |
| Data QA stage 2 (P2's tables) → P2 | Not started |
