# Cleaning Log

这里和 Google Sheet 的「6. Cleaning Log」tab 同步。每发现一个数据问题、或做一个处理决定，就加一行。
`check_name` 对应 `cleaning/Q1_quality_checklist/checklist.md`。修改检查标准时，`standard_version` 要升级（v1 → v2），并在「理由」列写明原因。

| 日期 | 项目 | 表 | 步骤 | check_name | standard_version | 发现的问题 | 影响行数 | 处理方式 | 理由 | SQL 文件 |
|---|---|---|---|---|---|---|---|---|---|---|
| 2026-10-13 | 共用 | — | S2 | — | — | 计费正常；raw、clean、analysis 都在 US；raw 没有设置表过期 | — | 无需处理 | — | — |
| 2026-10-13 | 共用 | geolocation | S1 | rows_completion | v1 | raw 里有 geolocation 表，但计划写的是跳过，导致 raw 有 11 张表 | 1,000,163 | 从 raw 删除这张表，raw 恢复为 10 张 | 三个项目都不用这张表；保持 raw 和计划一致 | — |
| 2026-10-13 | P1 | orders | Q1 | observation_window | v1 | 2018-08-30 之后每天只有个位数订单（最后一笔在 2018-10-17），用 MAX(下单时间) 当截止日会高估有完整 90 天窗口的商家数 | 25（2018-08-30 之后的订单） | 订单数据截止日定为 2018-08-30（处理假设，不是数据事实） | 截止日后的零星订单是数据导出的残留，不代表真实业务量 | cleaning/Q1_quality_checklist/sql/01_quality_checklist.sql |
