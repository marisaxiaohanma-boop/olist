# T2 处理粒度（一对多）

- **目的**：避免 JOIN 之后金额被重复计算。
- **实现**：一对多的表先汇总到订单级，再和其他表 JOIN。阶段 1：order_items 按 order_id 汇总，得到商品件数、GMV、运费（结果叫 order_items_agg）。阶段 2：order_payments 按 order_id 汇总；order_reviews 每单只取最新一条。
- **GMV 口径**：GMV = price 合计，不含运费。payment_value 含运费和分期利息，只用来对账。
- **判断规则**：汇总表的行数 = 不重复的 order_id 数。
- **状态**：阶段 1 未开始。
