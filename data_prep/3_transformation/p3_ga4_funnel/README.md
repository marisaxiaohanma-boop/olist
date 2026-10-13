# P3 · Transformation

**Not started.** P3 uses Google's public GA4 sample e-commerce data (`bigquery-public-data.ga4_obfuscated_sample_ecommerce`), not Olist, so it doesn't go through Olist's Data QA. Its preparation steps are set in [P3 scoping](../../../p3_ga4_funnel).

| Step | Purpose | Candidate rules |
|---|---|---|
| **T** · Transform | Turn event-level GA4 data into one row per session | Extract `ga_session_id` from the nested `event_params` with `UNNEST`; session key = `user_pseudo_id` + `ga_session_id`. Flag which funnel events each session reached. Report obfuscated values (`<Other>`, `(data deleted)`) as their own group rather than dropping them. Limit scans with `_TABLE_SUFFIX` |
| **R** · Reconcile | Prove the session table didn't lose events | Event and purchase counts in the session table match the source for the same date range |
