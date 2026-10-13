# P2 · Transformation

Turns the validated raw data into the clean tables P2 needs. **Not started.** P2's tables (`customers`, `order_payments`, `order_reviews`, `products`, `product_category_name_translation`) are first added to the shared [Data QA](../../2_data_qa) (stage 2). The final transform steps are then set in [P2 scoping](../../../p2_repeat_purchase).

| Step | Purpose | Candidate rules |
|---|---|---|
| **T** · Transform | Fix the issues Data QA found that matter for P2, and build P2's clean tables | Aggregate `order_items` and `order_payments` to one row per order before joining. Keep only the latest review per order (`review_id` is known to repeat). Translate product categories to English. Fix misspelled `*_lenght` columns |
| **R** · Reconciliation | Prove that nothing was dropped or duplicated by mistake | `ASSERT` that order counts and total GMV in `clean` equal `raw` minus the records excluded on purpose, with every difference logged |
