# S2 · Verify the BigQuery environment

- **Purpose:** rule out billing, region, and expiry problems before running anything.
- **Checks:** billing is enabled; `raw`, `clean`, and `analysis` are all in the US region (required to query the GA4 public dataset in P3); `raw` has no default table expiration.
- **Status:** ✅ Done. All three checks pass.
