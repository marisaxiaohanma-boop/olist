# Q1 Data Quality Findings — Stage 1

**Scope:** the five raw tables behind the lead-to-revenue funnel: `mql_leads`, `closed_deals`, `sellers`, `orders`, `order_items`
**Question:** is the raw data a faithful record of how Olist's business works? No data was changed in this step.
**Run date:** 2026-10-13 · **Standard:** [checklist v1](checklist.md) · **Business rules B1–B7:** defined in the [checklist](checklist.md#start-from-the-business-model)

---

## Summary

| Question | Answer |
|---|---|
| **Does the data follow the business model?** | **Yes**, with two small exceptions (1 deal, 1.7% of orders). |
| **Is critical data missing?** | **Yes.** Acquisition channel is missing for 14.5% of leads because of a tracking gap concentrated on one landing page. And 55% of signed sellers never appear in the order data. |
| **Do the tables join correctly?** | **Yes.** No orphans, no duplicate keys or rows, and row counts match the source exactly. |

---

## 1. Business model fit

| Rule | Result | Evidence |
|---|---|---|
| B1 · Every seller started as a lead | ✅ | All 842 deals map to a lead; 1 deal closes 2 days before first contact |
| B3 · Sellers sell only after signing | ✅ | 0 of 380 matched sellers have an order before their sign date |
| B4 · Each item belongs to one order and one seller | ✅ | 0 orphan items; (order, item) is unique |
| B5 · Orders follow a fixed lifecycle | ✅ | 0 orders delivered before purchase; only the 8 known statuses; 97% `delivered` |
| B6 · GMV is positive item prices | ✅ | 0 non-positive prices; max R$6,735 vs. 99th percentile R$890 |

**Exceptions, both handled in Transform:**
- **1 deal won before first contact.** Likely a data-entry error. It will be excluded.
- **1,655 orders (1.7%) stuck in progress** (`shipped`, `processing`, `invoiced`…) for 30+ days before the data cutoff. Their outcome is unknown, so they won't be counted as completed sales.

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
- **Treatment here:** merge `NULL` and `unknown` into one `unknown` value in T3. Keep these leads; don't drop them.

### 2b. 55% of signed sellers never appear in the order data (rule B3)

Only 380 of 842 signed sellers (45%) have any order. Late sign-ups explain part of this: 50 sellers signed after the order data ends. But sellers signed Jan–May 2018, with 3+ months to sell, still match at only 50–56%.

The data can't tell apart two explanations: (1) about half of signed sellers never start selling, or (2) the public order dataset doesn't cover every order.

- **Action for the data owner:** confirm whether the order data is complete for these sellers.
- **Treatment here:** none. The records are valid. How to interpret them is handed off to P1 (see below).

### 2c. Seller-profile fields are rarely filled in (lower priority)

Four fields in `closed_deals` are ~92% empty: `has_company`, `has_gtin`, `average_stock`, `declared_product_catalog_size`. `declared_monthly_revenue` has no NULLs, but 94.7% of its values are `0`, which in practice means "not filled in." These look like optional fields on the sales intake form.

The fields that define the funnel are complete: lead ID, first-contact date, sign date, seller ID, order ID, purchase timestamp, and price all have zero missing values.

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

| Check | Result | Key number |
|---|---|---|
| rows_completion | ✅ Pass | all 5 tables match |
| data_type | ✅ Pass | 0 dates stored as text |
| distinct_primary_key | ✅ Pass | 0 duplicate keys |
| null_check | ⚠️ See 2a, 2c | channel 14.5% missing |
| date_logic | ❌ Minor | 1 deal |
| value_range | ✅ Pass | 0 non-positive prices |
| category_values | ❌ Minor | 1,655 stuck orders |
| duplicate_rows | ✅ Pass | 0 |
| referential_integrity | ✅ Pass | 0 orphans |
| observation_window | ⚠️ See 2b | 45% match rate; 667 sellers signed ≥ 90 days before cutoff (threshold 100) |

## Hand-off to P1 scoping

This step raises the questions below but doesn't decide them. They're decided in P1, against P1's business question.

1. **Unknown channel:** how to present a channel ranking when 14.5% of leads, including much of a top-converting landing page, have no channel.
2. **Unmatched sellers:** whether a signed seller with no orders counts as "not activated," and how to state the coverage uncertainty from 2b.
3. **Order status:** which order statuses count toward GMV.
4. **Fields:** which `closed_deals` fields are in scope, given 2c.

## Files

| Query | Output |
|---|---|
| [`sql/01_quality_checklist.sql`](sql/01_quality_checklist.sql): every checklist check | [`results/quality_check_results_stage1.csv`](results/quality_check_results_stage1.csv) |
| [`sql/02_followups_stage1.sql`](sql/02_followups_stage1.sql): drill-downs on flagged results | [`results/followups_stage1.csv`](results/followups_stage1.csv) |
| [`sql/03_unknown_origin_diagnosis.sql`](sql/03_unknown_origin_diagnosis.sql): is unknown channel random or systematic? | [`results/unknown_origin_diagnosis.csv`](results/unknown_origin_diagnosis.csv) |

All issues and treatments are logged in [`docs/cleaning_log.md`](../../docs/cleaning_log.md). Written to the [findings standard](../../docs/findings_standard.md).
