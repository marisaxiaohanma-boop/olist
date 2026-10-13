# Cleaning Log

这里和 Google Sheet 的「6. Cleaning Log」tab 同步。每发现一个数据问题、或做一个处理决定，就加一行。
`check_name` 对应 `cleaning/Q1_quality_checklist/checklist.md`。修改检查标准时，`standard_version` 要升级（v1 → v2），并在「理由」列写明原因。

| 日期 | 项目 | 表 | 步骤 | check_name | standard_version | 发现的问题 | 影响行数 | 处理方式 | 理由 | SQL 文件 |
|---|---|---|---|---|---|---|---|---|---|---|
| 2026-10-13 | 共用 | — | S2 | — | — | 计费正常；raw、clean、analysis 都在 US；raw 没有设置表过期 | — | 无需处理 | — | — |
| 2026-10-13 | 共用 | geolocation | S1 | rows_completion | v1 | 计划写的是跳过 geolocation，但 raw 里实际有这张表（共 11 张，不是 10 张） | — | 待定：删除这张表，或在计划里注明保留 | 三个项目都不用这张表 | — |
