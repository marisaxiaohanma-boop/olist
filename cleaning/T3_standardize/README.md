# T3 · Standardize categorical values

- **Purpose:** make categorical fields consistent, so one category isn't split into several.
- **Method:** trim and lowercase categorical values. `mql_leads.origin`: map NULL and the literal `unknown` to a single `unknown` value. Stage 2: translate product categories to English and fix misspelled `*_lenght` columns.
- **Rule:** `unknown` is reported as its own group, never dropped.
- **Status:** Not started.
