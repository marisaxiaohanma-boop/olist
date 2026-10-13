# T2 · Fix one-to-many grain

- **Purpose:** prevent amounts from being double-counted after joins.
- **Method:** aggregate one-to-many tables to order level *before* joining. Stage 1: `order_items` → item count, GMV, and freight per order. Stage 2: `order_payments` summed per order; `order_reviews` keeps the latest review per order.
- **Why:** joining orders, items, and payments directly multiplies rows. An order with 3 items and 2 payments would be counted 6 times.
- **GMV definition:** sum of `price`, excluding freight. `payment_value` includes freight and installment interest and is used for reconciliation only.
- **Rule:** row count of each aggregate = distinct `order_id` count.
- **Status:** Not started.
