# Data cleaning

Cleaning happens in two layers:

| Layer | Folders | Question | Changes data? |
|---|---|---|---|
| **Shared: set up and validate** (once, for all projects) | `S1`–`S3`, `Q1` | Is the raw data loaded, and is it a faithful record of how the business works? | No (loads `raw` only) |
| **Per project: transform and reconcile** (after that project's scoping) | `p1_lead_quality/`, `p2_repeat_purchase/` | Given what this project needs, how do we fix the issues Q1 found, and did we lose anything? | Yes, writes `clean` |

Transform is per project because what counts as "clean" depends on the question. For example, which order statuses count as revenue is a P1 decision, not a data-quality fact.

Folders are named **phase letter + step number + short name**: **S** = Setup, **Q** = Quality checklist, **T** = Transform, **R** = Reconciliation. Each step folder contains `README.md`, `sql/`, `results/`, and `findings.md`.
