# Cleaning Log

这里和 Google Sheet 的「6. Cleaning Log」tab 同步。每发现一个数据问题、或做一个处理决定，就加一行。
`check_name` 对应 `cleaning/Q1_quality_checklist/checklist.md`。修改检查标准时，`standard_version` 要升级（v1 → v2），并在「理由」列写明原因。

| 日期 | 项目 | 表 | 步骤 | check_name | standard_version | 发现的问题 | 影响行数 | 处理方式 | 理由 | SQL 文件 |
|---|---|---|---|---|---|---|---|---|---|---|
| 2026-10-13 | 共用 | — | S2 | — | — | 计费正常；raw、clean、analysis 都在 US；raw 没有设置表过期 | — | 无需处理 | — | — |
| 2026-10-13 | 共用 | geolocation | S1 | rows_completion | v1 | raw 里有 geolocation 表，但计划写的是跳过，导致 raw 有 11 张表 | 1,000,163 | 从 raw 删除这张表，raw 恢复为 10 张 | 三个项目都不用这张表；保持 raw 和计划一致 | — |
| 2026-10-13 | P1 | orders | Q1 | observation_window | v1 | 2018-08-30 之后每天只有个位数订单（最后一笔在 2018-10-17），用 MAX(下单时间) 当截止日会高估有完整 90 天窗口的商家数 | 21（下单日期晚于 2018-08-30 的订单） | 订单数据截止日定为 2018-08-30（处理假设，不是数据事实） | 截止日后的零星订单是数据导出的残留，不代表真实业务量 | cleaning/Q1_quality_checklist/sql/01_quality_checklist.sql |
| 2026-10-13 | P1 | mql_leads | Q1 | null_check | v1 | origin 有 60 条 NULL，另外原始数据里已有 1,099 条取值就是 unknown | 1,159（14.5%） | T3 把 NULL 和 unknown 合并为 unknown，按渠道分析时单独列出，不删除 | 渠道是 P1 的核心分组字段，删除会让线索总数失真 | cleaning/Q1_quality_checklist/sql/02_followups_stage1.sql |
| 2026-10-13 | P1 | closed_deals | Q1 | null_check | v1 | has_company、has_gtin、average_stock、declared_product_catalog_size 约 92% 为空；lead_behaviour_profile 21% 为空 | 每列 773–779；177 | 前 4 列不进 clean 表；lead_behaviour_profile 只作参考 | 基本没有数据，无法支持拆分分析 | cleaning/Q1_quality_checklist/sql/01_quality_checklist.sql |
| 2026-10-13 | P1 | closed_deals | Q1 | null_check | v1 | declared_monthly_revenue 没有空值，但 94.7% 是 0（伪空值） | 797 | 不进 clean 表；建议 null_check 标准升级 v2，加入伪空值检查（待确认） | 0 实际代表“没填”，当数值用会误导 | cleaning/Q1_quality_checklist/sql/02_followups_stage1.sql |
| 2026-10-13 | P1 | closed_deals | Q1 | date_logic | v1 | 1 条成交的 won_date 比 first_contact_date 早 2 天（mql_id b91cf881…） | 1 | T4 生成 clean.closed_deals 时排除 | 数量很少，按 v1 标准排除并记录 | cleaning/Q1_quality_checklist/sql/02_followups_stage1.sql |
| 2026-10-13 | P1 | closed_deals | Q1 | date_logic | v1 | 有 50 家商家在订单数据截止日之后才成交（won_date 最晚到 2018-11-14） | 50 | 不单独处理；observation_window 只用 won_date ≤ 2018-06-01 的商家，会自动排除它们 | 这些商家在订单数据里不可能有订单 | cleaning/Q1_quality_checklist/sql/02_followups_stage1.sql |
| 2026-10-13 | P1/P2 | orders | Q1 | category_values | v1 | 下单超过 30 天还停在中间状态的订单：shipped 1,058、processing 301、invoiced 289、created 5、approved 2 | 1,655 | 分析只用 delivered，排除这些订单（P1 的状态口径待确认） | 长期停在中间状态，不能确定是否真的成交 | cleaning/Q1_quality_checklist/sql/01_quality_checklist.sql |
| 2026-10-13 | P1 | closed_deals | Q1 | observation_window | v1 | 成交商家中只有 45.1%（380/842）能在订单数据里找到订单；2018-01 到 05 成交的商家也只有 50–56% | 462 家对不上 | 有完整窗口的 667 家里，对不上订单的计为未激活；写进 P1 局限性（待确认） | 用现有数据分不清是真的没卖货，还是订单数据抽样没抽到 | cleaning/Q1_quality_checklist/sql/02_followups_stage1.sql |
| 2026-10-13 | P2 | orders | Q1 | null_check | v1 | 状态是 delivered 但没有送达日期 | 8 | 保留在复购计算中，从延迟分析中排除 | 订单确实完成了，但无法判断是否延迟 | cleaning/Q1_quality_checklist/sql/02_followups_stage1.sql |
