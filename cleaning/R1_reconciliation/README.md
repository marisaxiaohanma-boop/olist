# R1 · Reconcile raw vs. clean

- **Purpose:** prove that cleaning didn't silently drop or duplicate data.
- **Method:** `ASSERT` that order counts, seller counts, and total GMV in `clean` match `raw` minus the records excluded on purpose. Every difference must map to an entry in [`docs/cleaning_log.md`](../../docs/cleaning_log.md).
- **Rule:** any difference that can't be explained stops the pipeline.
- **Status:** Not started.
