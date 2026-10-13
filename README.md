# Olist Growth Analytics

我用 Olist 巴西电商公开数据做了一套增长诊断：获客（P1）、客户价值与留存（P2）、网站转化（P3，GA4 样例数据）。

- 数据仓库：BigQuery 项目 `olist001`。数据集分三个：`raw`（原始表，永远不改）、`clean`（清洗后的表）、`analysis`（分析结果），全部在 US。
- 完整计划写在 Google Sheet「Growth Analytics Portfolio Plan」里。

## 目录结构

```
cleaning/                  数据清洗，每一步一个文件夹
  S1_setup_load/           导入原始数据
  S2_env_check/            确认 BigQuery 环境
  S3_repo_setup/           建仓库（本仓库）
  Q1_quality_checklist/    清洗前质量检查（只检查，不改数据）
  T1_type_cast/            类型转换
  T2_grain/                处理粒度（一对多汇总）
  T3_standardize/          标准化
  T4_build_clean/          生成 clean 表
  R1_reconciliation/       清洗前后对账
p1_lead_quality/           P1 Lead Quality vs Lead Volume
p2_repeat_purchase/        P2 Repeat Purchase & Customer Value
p3_ga4_funnel/             P3 Website Conversion Funnel
scripts/                   可重复运行的脚本（例如导入）
docs/cleaning_log.md       所有清洗决定的总账，和 Sheet 里的 Cleaning Log tab 同步
```

每个步骤文件夹都用同一套结构，方便回头查：

| 文件 | 放什么 |
|---|---|
| `README.md` | 这一步的目的、实现逻辑和判断规则（来自计划） |
| `sql/` | 这一步跑过的 SQL，文件名带编号 |
| `results/` | SQL 跑出来的结果（CSV） |
| `findings.md` | 看完结果后的判断：Pass / Fail、怎么处理、为什么 |

原始 CSV 不放进仓库，用 `scripts/00_setup_and_load.sh` 从 Kaggle 下载后导入 BigQuery。
