# Data cleaning

Folders are named **phase letter + step number + short name** (e.g. `T2_grain` = Transform, step 2).

| Prefix | Phase | What it does |
|---|---|---|
| **S** | Setup | Load raw data and prepare the environment |
| **Q** | Quality checklist | Check that raw data reflects the business model, with no data changed |
| **T** | Transform | Fix what Q found and build the `clean` tables |
| **R** | Reconciliation | Verify that clean data matches raw, with every difference explained |

Each step folder contains `README.md` (method and rules), `sql/` (queries), `results/` (outputs), and `findings.md` (what the results mean). Full step list: [project README](../README.md#how-the-data-is-cleaned).
