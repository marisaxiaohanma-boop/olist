# Q1 Quality Checklist（清洗前，一次跑完）

- **目的**：动数据之前，先用一套事先定好的标准检查 raw 表的问题，再决定 Transform 要处理什么。这一步只检查，不改数据。
- **检查标准**：见 [checklist.md](checklist.md)，当前版本 v1。
- **SQL**：`sql/01_quality_checklist.sql`。每个检查一段查询，开头用注释写 check_name。每段统一输出 5 列：`check_name, table_name, metric, value, note`，最后用 UNION ALL 合并成一张结果表。
- **结果**：`results/quality_check_results_stage1.csv`（阶段 2 的结果另存 `_stage2.csv`）。
- **判断**：写在 `findings.md` 里，逐项标 Pass / Fail。Fail 的检查同步到 `docs/cleaning_log.md`。
- **状态**：阶段 1 已跑完（2026-10-13），判断见 [findings.md](findings.md)。追查查询在 `sql/02_followups_stage1.sql`。
