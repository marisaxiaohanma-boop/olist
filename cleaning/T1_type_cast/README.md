# T1 · Type conversion

- **Purpose:** make dates usable for day differences and amounts usable for sums.
- **Method:** columns flagged by `data_type` are cast with `SAFE_CAST`, and the number of failed casts is enforced to be 0 with `ASSERT`. TIMESTAMP and DATE values are normalized to DATE before comparison.
- **Stage 1 note:** Q1 found no date columns stored as text, so only DATE normalization is needed.
- **Status:** Not started.
