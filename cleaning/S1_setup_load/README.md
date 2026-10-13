# S1 Setup：导入原始数据

- **目的**：把 Kaggle 的 CSV 批量导入 `olist001.raw`，可以重复运行。
- **实现**：`scripts/00_setup_and_load.sh`。表名去掉前缀 `olist_` 和后缀 `_dataset`，`marketing_qualified_leads` 改名为 `mql_leads`，跳过 geolocation，导入时覆盖旧表。
- **判断规则**：raw 里应该有 10 张表，表名和后续 SQL 一致。缺表就补传，不在控制台手动改表。
- **状态**：已完成。注意：raw 里还有 geolocation，见 `docs/cleaning_log.md`。
