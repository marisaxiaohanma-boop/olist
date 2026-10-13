# T4 生成 clean 表

- **目的**：把 T1 到 T3 的处理固定下来，之后的分析只读 clean 表。
- **阶段 1**：`clean.mql_leads`、`clean.closed_deals`、`clean.seller_orders`（一行 = 一个商家的一笔订单）。
- **阶段 2**：`clean.orders`（订单级）。
- **判断规则**：对每张 clean 表重跑 rows_completion 和 distinct_primary_key，确认粒度正确。
- **状态**：阶段 1 未开始。
