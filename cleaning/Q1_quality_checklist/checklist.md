# Quality Checklist — Standard v1 (finalized 2026-10-13)

**Rule:** pass criteria are set *before* running any SQL. Results are judged against the criteria, never the other way around. If a check turns out to be missing or wrong after a run, the standard is bumped to v2 and the reason is logged in [`docs/cleaning_log.md`](../../docs/cleaning_log.md).

- **Stage 1** (before P1): `mql_leads`, `closed_deals`, `orders`, `order_items`, `sellers`
- **Stage 2** (before P2): `customers`, `order_payments`, `order_reviews`, `products`, `product_category_name_translation`

## Start from the business model

The goal of Q1 is to confirm that the raw data is a faithful record of how Olist works. So the checks are derived from the business, not from generic data-quality rules.

**How Olist works (stage 1 scope):** marketing generates a lead (MQL) through an acquisition channel → a sales rep closes the deal and the seller signs up → the seller lists products → customers place orders, which move through approval, shipping, and delivery. Olist earns a commission on item prices (GMV).

| # | Business rule | If the data follows it, we expect… | Checks |
|---|---|---|---|
| B1 | Every signed seller started as a marketing lead | Every deal maps to an MQL; the deal closes on or after first contact | referential_integrity, date_logic |
| B2 | Every lead is attributed to an acquisition channel | `origin` is filled for every lead | null_check |
| B3 | A seller sells only after signing up | No orders before the sign date; signed sellers appear in the order data | observation_window |
| B4 | Every item sold belongs to one order and one seller | No orphan items; one row per (order, item) | referential_integrity, distinct_primary_key |
| B5 | Orders follow a fixed lifecycle | Delivery after purchase; status is one of the known values; in-progress orders are recent | date_logic, category_values |
| B6 | GMV is the sum of positive item prices | `price` > 0, `freight_value` ≥ 0, extremes are explainable | value_range |
| B7 | One record per real-world entity, and the full dataset is present | Unique keys; no duplicate rows; row counts match the source | distinct_primary_key, duplicate_rows, rows_completion |

`data_type` is a technical prerequisite for all of the above.

This is a loop, not a one-way pass: the rules shape the checks, and the results feed back into our understanding of the business. In stage 1, for example, B2 turned out to be broken *systematically* (one landing page doesn't record its channel). That's a tracking problem at the source, not a random gap. See [findings](findings.md).

## Checks

| # | check_name | What it checks | Pass criteria (v1) | If it fails | Tables | Stage |
|---|---|---|---|---|---|---|
| 1 | rows_completion | Every table loaded completely | Row counts equal the published Kaggle counts (see below) | Check for an interrupted load; re-run S1 | all 10 | 1, 2 |
| 2 | data_type | Dates, amounts, and IDs have the right types | Dates are DATE / TIMESTAMP; `price`, `freight_value`, `payment_value` are FLOAT64 / NUMERIC; IDs are STRING. Any date stored as STRING must cast with 0 failures | Note the columns for each project's transform; inspect raw values that fail to cast | all | 1, 2 |
| 3 | distinct_primary_key | Each table's grain is what we think it is | Row count = distinct key count for `orders`, `sellers`, `mql_leads`, `closed_deals`, `customers`, `products`, `order_reviews`. Multiple rows per order in `order_items` / `order_payments` is expected | Check whether duplicates are exact copies or different content; one-to-many grain is handled in each project's transform | 7 tables listed | 1, 2 |
| 4 | null_check | Missing values in each column | No single threshold; judged column by column (see below) | Accept, exclude, or investigate per column | all | 1, 2 |
| 5 | date_logic | Events happen in a sensible order | Delivery ≥ purchase; `won_date` ≥ `first_contact_date`; date ranges match the dataset docs | Few rows: exclude and log. Many rows: stop and investigate | `orders`, `closed_deals`, `mql_leads` | 1, 2 |
| 6 | value_range | Amounts and scores are plausible | `price` > 0; `freight_value` ≥ 0; `review_score` in 1–5; extremes are rare and explainable | Inspect samples; exclude, keep, or flag | `order_items`, `order_payments`, `order_reviews` | 1, 2 |
| 7 | category_values | Categorical fields contain only expected values | `order_status` has only known values; in-progress orders are not old | Analyze `delivered` only; exclude and count long-stuck orders | `orders` | 1 |
| 8 | duplicate_rows | No fully duplicated rows | 0, or known and explainable | De-duplicate and log the count | all | 1, 2 |
| 9 | referential_integrity | Tables join without orphans | `order_items.order_id` ⊂ `orders`; `order_items.seller_id` ⊂ `sellers`; `closed_deals.mql_id` ⊂ `mql_leads`; `orders.customer_id` ⊂ `customers` | Log orphan count and share; assess impact | `order_items`, `orders`, `sellers`, `closed_deals`, `mql_leads`, `customers` | 1, 2 |
| 10 | observation_window | Signed sellers can be linked to orders, with enough follow-up time | Report the match rate of signed sellers in `order_items`; ≥ 100 sellers signed at least 90 days before the order-data cutoff (2018-08-30) | Low match rate or too few sellers: record as a limitation; consider a 60- or 30-day window | `closed_deals`, `order_items`, `orders` | 1 |
| 11 | category_translation_coverage | Product categories can be translated to English | Coverage close to 100% | List uncovered categories; add manually or map to `unknown` | `products`, `product_category_name_translation` | 2 |

### Expected row counts (published Kaggle dataset)

| Table | Rows | Table | Rows |
|---|---|---|---|
| mql_leads | 8,000 | customers | 99,441 |
| closed_deals | 842 | order_payments | 103,886 |
| orders | 99,441 | order_reviews | 99,224 |
| order_items | 112,650 | products | 32,951 |
| sellers | 3,095 | product_category_name_translation | 71 |

### Order-data cutoff: 2018-08-30

This is a **processing assumption, not a fact in the data**. Daily orders drop to single digits after 2018-08-29, and only 21 orders fall after 2018-08-30 (the last one is on 2018-10-17). Using the maximum order date as the cutoff would overstate how many sellers have a full 90-day window.

## null_check: column-by-column hypotheses (written before the run)

| Table | Column | What a NULL probably means | Treatment |
|---|---|---|---|
| mql_leads | origin | Channel wasn't recorded | Label `unknown` and report separately; don't drop |
| closed_deals | business_segment, lead_type, business_type | Sales rep didn't fill it in | Decide after the run |
| orders | order_id, customer_id | Should never be NULL | Any NULL must be investigated |
| orders | order_approved_at | Payment wasn't approved (e.g. canceled) | Decide after the run |
| orders | order_delivered_customer_date | Not delivered yet, or canceled | If `delivered` but NULL: keep for repeat-purchase metrics, exclude from delivery-delay analysis |
| products | product_category_name | Seller didn't set a category | Decide after the run (stage 2) |
| order_reviews | review_comment_message | Customer rated without commenting (normal) | Accept (stage 2) |

## Known in advance (stage 2)

`order_reviews.review_id` is known to have a few hundred duplicates in this dataset (the same review is attached to multiple orders), so `distinct_primary_key` is expected to fail there. P2's transform plans to keep only the latest review per order.
