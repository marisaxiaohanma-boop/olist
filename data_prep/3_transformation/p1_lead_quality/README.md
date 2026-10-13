# P1 · Transformation

Turns the validated raw data into the clean tables P1 needs. **Not started.** The steps below are candidates; the final list is set in [P1 scoping](../../../p1_lead_quality), which decides which tables, fields, and records P1 uses.

| Step | Purpose | Candidate rules |
|---|---|---|
| **T** · Transform | Fix the issues [Data QA](../../2_data_qa/findings.md) found that matter for P1, and build P1's clean tables | Align TIMESTAMP and DATE before comparing dates. Map missing and `unknown` acquisition channel to one `unknown` group. Exclude the deal won before first contact. Aggregate `order_items` to one row per order **before** joining, so revenue isn't double-counted |
| **R** · Reconciliation | Prove that nothing was dropped or duplicated by mistake | `ASSERT` that lead, deal, seller, and order counts and total GMV in `clean` equal `raw` minus the records excluded on purpose. Every difference must match an entry in the [data prep log](../../../docs/data_prep_log.md) |

**GMV definition:** sum of item `price`, excluding freight. (`payment_value` includes freight and installment interest, so it's used for reconciliation only.)

Steps will be numbered `T1_…`, `T2_…`, `R1_…`, each with `sql/`, `results/`, and `findings.md`.
