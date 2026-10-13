# Data QA Findings — Stage 1

**Scope:** the five raw tables behind the lead-to-revenue funnel: `mql_leads`, `closed_deals`, `sellers`, `orders`, `order_items`
**Question:** is the raw data a faithful record of how Olist's business works? No data was changed in this step.
**Run date:** 2026-10-13 · **Standard:** [checklist v1](checklist.md) · **Business rules B1–B7:** defined in the [checklist](checklist.md#start-from-the-business-model)

---

## Summary

| Question | Answer |
|---|---|
| **Does the data follow the business model?** | **Yes.** Leads, deals, sellers, and orders link up in the expected order. One deal is dated impossibly early. |
| **Is critical data missing?** | **Three gaps.** (a) Acquisition channel is missing for 14.5% of leads, from a tracking gap concentrated on one landing page. (b) 55% of signed sellers never appear in the order data. (c) 1,655 orders (1.7%) never had their final outcome recorded. All other funnel fields are complete. |
| **Do the tables join correctly?** | **Yes.** No orphans, no duplicate keys or rows, and row counts match the source exactly. |

---

## 1. Business model fit

| Rule | Result | Evidence |
|---|---|---|
| B1 · Every seller started as a lead | ✅ | All 842 deals map to a lead; 1 deal closes 2 days before first contact |
| B3 · Sellers sell only after signing | ✅ | 0 of 380 matched sellers have an order before their sign date |
| B4 · Each item belongs to one order and one seller | ✅ | 0 orphan items; (order, item) is unique |
| B5 · Orders follow a fixed lifecycle | ⚠️ | 0 orders delivered before purchase; only the 8 known statuses; 97% `delivered`. But 1.7% of orders never reach a final status (see 2c) |
| B6 · GMV is positive item prices | ✅ | 0 non-positive prices; max R$6,735 vs. 99th percentile R$890 |

**Exception:** 1 deal is marked won 2 days before the lead's first contact. That's impossible, so it's most likely a data-entry error. Recommended: exclude it in any project that uses deal dates.

## 2. Critical missing data

### 2a. Acquisition channel isn't tracked for one major entry point (rule B2)

1,159 of 8,000 leads (14.5%) have no channel: 60 are `NULL` and 1,099 are tagged `unknown`. Three tests show this is a systematic tracking gap, not random noise:

| Test | Result | Rules out |
|---|---|---|
| Share by month | Steady at 13–18% every month | A one-time outage |
| Share by landing page | 57% of unknowns (657) come from one page, `b76ef374…`; 72% of that page's leads are untagged | Gaps spread randomly |
| Close rate | Unknown leads close at 16.7% vs. 9.5% for tagged leads | Untagged leads being low-quality noise |

That same page is one of Olist's two largest sources of closed deals: 171 of 842 (20%), with an 18.8% close rate vs. 10.5% overall. **One of the best-performing entry points is the one whose channel isn't recorded.**

- **Action for the data owner:** audit source / UTM tagging on page `b76ef374…`, which accounts for over half the gap. Then make `origin` required at lead capture, with no default to `unknown`.
- **Recommended handling:** merge `NULL` and `unknown` into one `unknown` group, and keep these leads rather than dropping them.

### 2b. 55% of signed sellers never appear in the order data (rule B3)

Only 380 of 842 signed sellers (45%) have any order. Late sign-ups explain part of this: 50 sellers signed after the order data ends. But sellers signed Jan–May 2018, with 3+ months to sell, still match at only 50–56%.

The data can't tell apart two explanations: (1) about half of signed sellers never start selling, or (2) the public order dataset doesn't cover every order.

- **Action for the data owner:** confirm whether the order data is complete for these sellers.
- **Recommended handling:** none. The records are valid. How to interpret them is handed off to P1 (see below).

### 2c. 1,655 orders never had their final outcome recorded (rule B5)

Every order should end as `delivered`, `canceled`, or `unavailable`. But 1,655 orders (1.7%) placed more than 30 days before the data cutoff are still `shipped` (1,058), `processing` (301), `invoiced` (289), `created` (5), or `approved` (2). They aren't simply slow deliveries:

| Test | Result | What it shows |
|---|---|---|
| Promised delivery date | **All 1,655** are past the delivery date promised to the customer | No order should still be in transit |
| Age | Median age is 8–16 months, depending on status | Far beyond any normal delivery time |
| Lifecycle timestamps | All 1,058 `shipped` orders were handed to the carrier; **none** has a delivery date | The process stopped after carrier handoff; no outcome came back |
| Share by quarter | Falls steadily from 8.6% (Q4 2016) to 1.2% (Q3 2018) | Not a one-time system outage; an ongoing gap that shrank as the platform matured |

**Conclusion:** these orders were most likely delivered, lost, or canceled, but the outcome was never written back to `order_status`. The status field stops updating for a small, persistent share of orders, especially after carrier handoff.

- **Action for the data owner:** reconcile these orders with carrier and payment records, and add a rule that closes any order still open after its promised delivery date (e.g. flag as `lost` or `unresolved`).
- **Recommended handling:** keep the records, but don't count them as completed sales.

### 2d. Every field the funnel depends on is complete

Lead ID, first-contact date, sign date, seller ID, order ID, purchase timestamp, and price have **zero** missing values. Outside 2a–2c, no gap prevents tracing a lead through to revenue.

What *is* incomplete is optional seller-profile data from the sales intake form. `has_company`, `has_gtin`, `average_stock`, and `declared_product_catalog_size` are ~92% empty. `declared_monthly_revenue` is 94.7% `0`, a placeholder for "not filled in." Whether any project needs these fields is a scoping question (see hand-off).

## 3. Integrity

| Check | Result |
|---|---|
| Row counts vs. published dataset | Exact match: 8,000 / 842 / 3,095 / 99,441 / 112,650 |
| Unique primary keys | All 5 tables |
| Fully duplicated rows | 0 |
| Orphans: `order_items` → `orders` / `sellers`; `closed_deals` → `mql_leads` | 0 / 0 / 0 |
| Column types | Correct as loaded; no type conversion needed |

---

## Check-by-check results (standard v1)

✅ meets the standard · ⚠️ no pass/fail threshold was set in advance, so the result needs interpretation · ❌ breaks the standard

Data QA doesn't change any data. **Treatment** is the recommended handling; each project applies the treatments relevant to its scope in its own transform step ([`3_transformation/`](../3_transformation)).

| Check | Passes if… | Result | What we found | What it means | Treatment |
|---|---|---|---|---|---|
| rows_completion | Every table has exactly the published row count | ✅ | `mql_leads` 8,000 · `closed_deals` 842 · `sellers` 3,095 · `orders` 99,441 · `order_items` 112,650, all exact | The load was complete; nothing was cut off or appended twice | — |
| data_type | Dates are DATE / TIMESTAMP, amounts are numeric, IDs are text | ✅ | All 37 columns have the expected type; 0 dates stored as text | Dates and amounts can be used directly | No conversion needed; align TIMESTAMP and DATE before comparing them |
| distinct_primary_key | Each lead, deal, seller, order, and order item appears once | ✅ | 0 duplicate keys in all 5 tables | One row = one real-world record, so counts and sums won't be inflated | — |
| null_check | Judged column by column (no single threshold) | ⚠️ | Funnel fields (IDs, dates, prices): 0 missing. Acquisition channel: 1,159 leads (14.5%) missing. Seller-profile fields: ~92% empty, plus `declared_monthly_revenue` 94.7% `0` | The funnel is fully traceable, except that channel attribution has a systematic tracking gap on one landing page (2a). Profile fields are optional and rarely filled in (2d) | Keep leads with no channel as one `unknown` group. Profile fields: flagged, decided in P1 scoping |
| date_logic | A deal can't close before the lead's first contact; an order can't be delivered before it's placed | ❌ | 1 of 842 deals is marked won 2 days before first contact. 0 orders delivered before purchase | An impossible sequence, most likely a data-entry error on one record. Not a pattern | Exclude that one deal |
| value_range | Prices > 0, freight ≥ 0, extremes are explainable | ✅ | 0 zero or negative prices or freight. Median price R$75, 99th percentile R$890, max R$6,735 | High prices are rare and plausible for a general marketplace (e.g. electronics, furniture) | Keep all values |
| category_values | Order status is a known value, and orders still in progress are recent | ❌ | Statuses are all valid, but 1,655 orders (1.7%) placed 30+ days before the cutoff are still `shipped`, `processing`, `invoiced`, `created`, or `approved`. All are past their promised delivery date; median age 8–16 months | These orders didn't get stuck in transit; their final outcome (delivered, lost, or canceled) was never recorded. A status-tracking gap, not slow delivery (2c) | Keep the records, but don't count them as completed sales |
| duplicate_rows | No row appears twice | ✅ | 0 fully duplicated rows in all 5 tables | No double-counting from repeated loads | — |
| referential_integrity | Every order item links to an order and a seller; every deal links to a lead | ✅ | 0 orphans across all 3 links | Lead → deal → seller → order can be joined end to end without losing records | — |
| observation_window | Signed sellers can be found in the order data, and ≥ 100 signed early enough to observe for 90 days | ⚠️ | 380 of 842 signed sellers (45%) appear in the order data. Even sellers signed Jan–May 2018 only match at 50–56%. 667 signed ≥ 90 days before the cutoff (threshold 100) | There's enough follow-up time, but half of signed sellers never show up in orders. Either they never started selling, or the order data is incomplete; the data can't tell which (2b) | No change to the data. Interpretation handed off to P1 |

## Hand-off to P1 scoping

This step raises the questions below but doesn't decide them. They're decided in P1, against P1's business question.

1. **Unknown channel:** how to present a channel ranking when 14.5% of leads, including much of a top-converting landing page, have no channel.
2. **Unmatched sellers:** whether a signed seller with no orders counts as "not activated," and how to state the coverage uncertainty from 2b.
3. **Order status:** which order statuses count toward GMV.
4. **Fields:** which `closed_deals` fields are in scope, given 2d.

## Files

| Query | Output |
|---|---|
| [`sql/01_quality_checklist.sql`](sql/01_quality_checklist.sql): every checklist check | [`results/quality_check_results_stage1.csv`](results/quality_check_results_stage1.csv) |
| [`sql/02_followups_stage1.sql`](sql/02_followups_stage1.sql): drill-downs on flagged results | [`results/followups_stage1.csv`](results/followups_stage1.csv) |
| [`sql/03_unknown_origin_diagnosis.sql`](sql/03_unknown_origin_diagnosis.sql): is unknown channel random or systematic? | [`results/unknown_origin_diagnosis.csv`](results/unknown_origin_diagnosis.csv) |
| [`sql/04_stuck_orders_diagnosis.sql`](sql/04_stuck_orders_diagnosis.sql): are in-progress orders in transit, or was their outcome never recorded? | [`results/stuck_orders_diagnosis.csv`](results/stuck_orders_diagnosis.csv) |

All issues and treatments are logged in [`docs/data_prep_log.md`](../../docs/data_prep_log.md). Written to the [findings standard](../../docs/findings_standard.md).
