# 3 · Transformation

One folder per project. Each starts after that project's scoping and has two kinds of steps:

| Prefix | Step | What it does |
|---|---|---|
| **T** | Transform | Apply the [Data QA](../2_data_qa/findings.md) treatments relevant to the project, and build its `clean` tables |
| **R** | Reconcile | `ASSERT` that `clean` equals `raw` minus the records excluded on purpose, with every difference explained in the [cleaning log](../../docs/cleaning_log.md) |

| Folder | Status |
|---|---|
| [`p1_lead_quality`](p1_lead_quality) | Not started (after P1 scoping) |
| [`p2_repeat_purchase`](p2_repeat_purchase) | Not started (after Data QA stage 2 and P2 scoping) |
| [`p3_ga4_funnel`](p3_ga4_funnel) | Not started (after P3 scoping) |
